import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../commons/widgets/app_text_field.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/savings_goal_providers.dart';

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
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
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
          title: const Text('Delete Savings Goal'),
          content: const Text('Are you sure you want to permanently delete this savings goal?'),
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
                style: TextStyle(color: AppColors.expense),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Goal' : 'Add Goal'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              tooltip: 'Delete Savings Goal',
              onPressed: isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Goal Name field
            Text(
              'GOAL NAME',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            AppTextField(
              controller: _nameController,
              label: 'e.g. New Laptop, Emergency Fund',
              prefixIcon: const Icon(Icons.title_rounded),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Goal name is required';
                return null;
              },
            ),
            VSpace.xl,

            // Target Amount field
            Text(
              'TARGET AMOUNT',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            AppTextField(
              controller: _targetAmountController,
              label: 'How much do you need to save?',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Target amount is required';
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter a valid positive amount';
                }
                return null;
              },
            ),
            VSpace.xl,

            // Current Saved field
            Text(
              'CURRENT SAVED',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            AppTextField(
              controller: _currentAmountController,
              label: 'How much have you already saved?',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.savings_rounded),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Current saved amount is required';
                if (double.tryParse(val) == null || double.parse(val) < 0) {
                  return 'Enter a valid non-negative amount';
                }
                return null;
              },
            ),
            VSpace.xl,

            // Target Date picker tile
            Text(
              'TARGET DATE',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
                side: const BorderSide(color: AppColors.border),
              ),
              leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
              title: Text(
                DateFormat('dd MMMM yyyy').format(_selectedDate),
                style: AppTextStyles.body,
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _presentDatePicker,
            ),
            VSpace.xl,

            PrimaryButton(
              text: _isEditMode ? 'Update Savings Goal' : 'Create Savings Goal',
              onPressed: isLoading ? null : _submitForm,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
