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
import '../../domain/entities/subscription.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_providers.dart';

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
  late DateTime _selectedDate;

  bool get _isEditMode => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _amountController = TextEditingController(
      text: sub != null ? sub.amount.toStringAsFixed(0) : '',
    );
    _selectedCycle = sub?.billingCycle ?? BillingCycle.monthly;
    _selectedDate = sub?.nextBillingDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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

    final costVal = double.tryParse(_amountController.text);
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
      nextBillingDate: _selectedDate,
      createdAt: widget.subscription?.createdAt ?? DateTime.now(),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subscription'),
          content: const Text('Are you sure you want to permanently stop tracking this subscription?'),
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
                      .read(subscriptionControllerProvider.notifier)
                      .deleteSubscription(widget.subscription!.id);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Subscription deleted successfully')),
                  );
                  if (mounted) this.context.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting subscription: $e')),
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
    final controllerState = ref.watch(subscriptionControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Subscription' : 'Add Subscription'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              tooltip: 'Delete Subscription',
              onPressed: isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Name field
            Text(
              'SUBSCRIPTION NAME',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            AppTextField(
              controller: _nameController,
              label: 'e.g. Netflix, iCloud, Gym',
              prefixIcon: const Icon(Icons.title_rounded),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Subscription name is required';
                return null;
              },
            ),
            VSpace.xl,

            // Cost field
            Text(
              'RECURRING COST',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            AppTextField(
              controller: _amountController,
              label: 'How much do you pay?',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Cost amount is required';
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter a valid positive amount';
                }
                return null;
              },
            ),
            VSpace.xl,

            // Billing Cycle field
            Text(
              'BILLING CYCLE',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            DropdownButtonFormField<BillingCycle>(
              value: _selectedCycle,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                prefixIcon: const Icon(Icons.repeat_rounded, color: AppColors.primary),
              ),
              items: BillingCycle.values.map((cycle) {
                final cycleName = cycle.name[0].toUpperCase() + cycle.name.substring(1);
                return DropdownMenuItem<BillingCycle>(
                  value: cycle,
                  child: Text(cycleName, style: AppTextStyles.body),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCycle = val;
                  });
                }
              },
            ),
            VSpace.xl,

            // Next Billing Date field
            Text(
              'NEXT RENEWAL DATE',
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
              text: _isEditMode ? 'Update Subscription' : 'Track Subscription',
              onPressed: isLoading ? null : _submitForm,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
