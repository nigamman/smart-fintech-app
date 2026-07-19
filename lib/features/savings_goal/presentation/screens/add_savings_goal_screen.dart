import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/savings_goal_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class AddSavingsGoalScreen extends ConsumerStatefulWidget {
  final SavingsGoal? savingsGoal;

  const AddSavingsGoalScreen({
    super.key,
    this.savingsGoal,
  });

  @override
  ConsumerState<AddSavingsGoalScreen> createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends ConsumerState<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentAmountController;
  late DateTime _selectedDate;

  bool get _isEditMode => widget.savingsGoal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.savingsGoal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _nameController.addListener(() {
      setState(() {}); // refresh letter chip dynamically
    });
    _targetAmountController = TextEditingController(
      text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '',
    );
    _currentAmountController = TextEditingController(
      text: goal != null ? goal.currentAmount.toStringAsFixed(0) : '0',
    );
    _selectedDate = goal?.targetDate ?? DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final targetVal = double.tryParse(_targetAmountController.text);
    if (targetVal == null || targetVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount.')),
      );
      return;
    }

    final currentVal = double.tryParse(_currentAmountController.text) ?? 0.0;
    if (currentVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid current amount.')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final goal = SavingsGoal(
      id: widget.savingsGoal?.id ?? const Uuid().v4(),
      userId: user.id,
      name: _nameController.text.trim(),
      targetAmount: targetVal,
      currentAmount: currentVal,
      targetDate: _selectedDate,
      createdAt: widget.savingsGoal?.createdAt ?? DateTime.now(),
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savingsGoalControllerProvider.notifier).saveGoal(goal);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Goal updated successfully' : 'Goal saved successfully'),
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving savings goal: $e')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Savings Goal', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to permanently delete this savings goal?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                try {
                  await ref
                      .read(savingsGoalControllerProvider.notifier)
                      .deleteGoal(widget.savingsGoal!.id);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Savings goal deleted successfully')),
                  );
                  if (mounted) this.context.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting savings goal: $e')),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFBC5B3E)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(savingsGoalControllerProvider);
    final isLoading = controllerState.isLoading;
    final currency = ref.watch(preferencesProvider).currency;

    final firstLetter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Custom Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Edit goal' : 'Add goal',
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isEditMode)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBC5B3E)),
                          tooltip: 'Delete Savings Goal',
                          onPressed: isLoading ? null : _confirmDelete,
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 1.0),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // GOAL NAME field
              Text(
                'GOAL NAME',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.disabledText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Goal name is required';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. New Laptop, Emergency Fund...',
                          hintStyle: TextStyle(
                            color: AppColors.secondaryText.withOpacity(0.4),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    if (firstLetter.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Centered large gold Amount field
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Superscript currency symbol
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Text(
                        currency,
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Dynamic width white text input
                    SizedBox(
                      width: (_targetAmountController.text.isEmpty ? 1 : _targetAmountController.text.length) * 34.0 + 20.0,
                      child: TextFormField(
                        controller: _targetAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.left,
                        cursorColor: AppColors.primary, // Custom gold cursor
                        cursorWidth: 2.0,
                        cursorHeight: 48,
                        style: GoogleFonts.fraunces(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White digits
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Target amount is required';
                          if (double.tryParse(val) == null || double.parse(val) <= 0) {
                            return 'Enter a valid target';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: GoogleFonts.fraunces(
                            fontSize: 54,
                            color: Colors.white.withOpacity(0.3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {}); // refresh width dynamically
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Center(
                child: Text(
                  'Target amount for this goal',
                  style: AppTextStyles.monoSecondary.copyWith(
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Starting saved amount field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starting deposit',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _currentAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: AppTextStyles.mono.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Current saved amount is required';
                              if (double.tryParse(val) == null || double.parse(val) < 0) {
                                return 'Enter valid deposit';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Target Date Selector Row
              GestureDetector(
                onTap: _presentDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target date',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Save goal Action Button
              BouncyButton(
                onTap: isLoading ? null : _submitForm,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isEditMode ? 'Save changes' : 'Save goal',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
