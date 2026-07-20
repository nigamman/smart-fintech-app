import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/thousands_formatter.dart';
import '../../../../core/extensions/num_extensions.dart';
import 'package:uuid/uuid.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const AddSubscriptionScreen({
    super.key,
    this.subscription,
  });

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late BillingCycle _selectedCycle;
  late DateTime _startDate;
  late DateTime _nextBillingDate;

  bool get _isEditMode => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _nameController.addListener(() {
      setState(() {}); // refresh letter chip dynamically
    });
    _amountController = TextEditingController(
      text: sub != null ? sub.amount.toCommaFormat() : '',
    );
    _selectedCycle = sub?.billingCycle ?? BillingCycle.monthly;
    _startDate = sub?.createdAt ?? DateTime.now();
    _nextBillingDate = sub?.nextBillingDate ?? _calculateNextBillingDate(_startDate, _selectedCycle);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  DateTime _calculateNextBillingDate(DateTime start, BillingCycle cycle) {
    if (cycle == BillingCycle.weekly) {
      return start.add(const Duration(days: 7));
    } else if (cycle == BillingCycle.yearly) {
      return start.add(const Duration(days: 365));
    } else {
      // Monthly
      return DateTime(start.year, start.month + 1, start.day);
    }
  }

  void _presentStartDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
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

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _nextBillingDate = _calculateNextBillingDate(_startDate, _selectedCycle);
      });
    }
  }

  void _presentNextDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: _startDate,
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

    if (picked != null) {
      setState(() {
        _nextBillingDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final costVal = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (costVal == null || costVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid cost.')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final sub = Subscription(
      id: widget.subscription?.id ?? const Uuid().v4(),
      userId: user.id,
      name: _nameController.text.trim(),
      amount: costVal,
      billingCycle: _selectedCycle,
      nextBillingDate: _nextBillingDate,
      createdAt: _startDate, // Map startsOn to createdAt
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subscriptionControllerProvider.notifier).saveSubscription(sub);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Subscription updated successfully' : 'Subscription saved successfully'),
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving subscription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(subscriptionControllerProvider);
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
                    _isEditMode ? 'Edit subscription' : 'Add subscription',
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
              const SizedBox(height: 30),

              // PROVIDER NAME Input Area
              Text(
                'PROVIDER NAME',
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
                          if (val == null || val.trim().isEmpty) return 'Provider name is required';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Netflix, Spotify, gym...',
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
                      width: (_amountController.text.isEmpty ? 1 : _amountController.text.length) * 34.0 + 20.0,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsFormatter()],
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
                          if (val == null || val.isEmpty) return 'Cost amount is required';
                          final cleanVal = val.replaceAll(',', '');
                          if (double.tryParse(cleanVal) == null || double.parse(cleanVal) <= 0) {
                            return 'Enter a valid cost';
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
                          setState(() {}); // refresh calculations and width dynamically
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BILLING CYCLE field
              Text(
                'BILLING CYCLE',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.disabledText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildCycleTab('Weekly', BillingCycle.weekly)),
                    Expanded(child: _buildCycleTab('Monthly', BillingCycle.monthly)),
                    Expanded(child: _buildCycleTab('Yearly', BillingCycle.yearly)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Starts on Date Selector Row
              GestureDetector(
                onTap: _presentStartDatePicker,
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
                        'Starts on',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(_startDate),
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
              const SizedBox(height: 12),

              // Next billing date Date Selector Row
              GestureDetector(
                onTap: _presentNextDatePicker,
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
                        'Next billing date',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(_nextBillingDate),
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

              // Save subscription Action Button
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
                    _isEditMode ? 'Save changes' : 'Save subscription',
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

  Widget _buildCycleTab(String label, BillingCycle cycle) {
    final isActive = _selectedCycle == cycle;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCycle = cycle;
          _nextBillingDate = _calculateNextBillingDate(_startDate, _selectedCycle);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.background : AppColors.primaryText,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
