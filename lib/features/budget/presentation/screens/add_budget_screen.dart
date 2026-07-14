import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../commons/widgets/app_text_field.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({
    super.key,
    this.budget,
  });

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late bool _isCategorySpecific;
  TransactionCategory? _selectedCategory;

  bool get _isEditMode => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _amountController = TextEditingController(
      text: b != null ? b.limitAmount.toStringAsFixed(0) : '',
    );
    _isCategorySpecific = b?.category != null;
    _selectedCategory = b?.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return Icons.account_balance_wallet_rounded;
      case TransactionCategory.freelance:
        return Icons.work_outline_rounded;
      case TransactionCategory.investment:
        return Icons.trending_up_rounded;
      case TransactionCategory.gift:
        return Icons.card_giftcard_rounded;
      case TransactionCategory.food:
        return Icons.restaurant_rounded;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TransactionCategory.travel:
        return Icons.directions_car_rounded;
      case TransactionCategory.bills:
        return Icons.receipt_long_rounded;
      case TransactionCategory.entertainment:
        return Icons.movie_creation_outlined;
      case TransactionCategory.health:
        return Icons.medical_services_outlined;
      case TransactionCategory.education:
        return Icons.school_rounded;
      case TransactionCategory.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionCategory.other:
        return Icons.category_rounded;
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCategorySpecific && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final now = DateTime.now();
    final budget = Budget(
      id: widget.budget?.id ?? const Uuid().v4(),
      userId: user.id,
      limitAmount: amount,
      category: _isCategorySpecific ? _selectedCategory : null,
      month: widget.budget?.month ?? now.month,
      year: widget.budget?.year ?? now.year,
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(budgetControllerProvider.notifier).saveBudget(budget);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Budget updated successfully' : 'Budget saved successfully'),
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving budget: $e')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget Limit'),
          content: const Text('Are you sure you want to permanently delete this budget limit?'),
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
                      .read(budgetControllerProvider.notifier)
                      .deleteBudget(widget.budget!.id);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Budget limit deleted successfully')),
                  );
                  if (mounted) this.context.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting budget: $e')),
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
    final controllerState = ref.watch(budgetControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Budget' : 'Add Budget'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              tooltip: 'Delete Budget Limit',
              onPressed: isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Budget Type Toggle
            Text(
              'BUDGET TYPE',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _isEditMode
                        ? null // Block toggling type in edit mode for schema security
                        : () {
                            setState(() {
                              _isCategorySpecific = false;
                            });
                          },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: !_isCategorySpecific
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: !_isCategorySpecific ? AppColors.primary : AppColors.border,
                          width: !_isCategorySpecific ? 1.5 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Monthly Budget',
                        style: AppTextStyles.button.copyWith(
                          color: !_isCategorySpecific ? AppColors.primary : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
                HSpace.md,
                Expanded(
                  child: InkWell(
                    onTap: _isEditMode
                        ? null
                        : () {
                            setState(() {
                              _isCategorySpecific = true;
                            });
                          },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isCategorySpecific
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: _isCategorySpecific ? AppColors.primary : AppColors.border,
                          width: _isCategorySpecific ? 1.5 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Category Budget',
                        style: AppTextStyles.button.copyWith(
                          color: _isCategorySpecific ? AppColors.primary : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            VSpace.xl,

            // Limit amount input field
            Text(
              'LIMIT AMOUNT',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            VSpace.md,
            AppTextField(
              controller: _amountController,
              label: 'Enter limit amount',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Amount is required';
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            VSpace.xl,

            // Category picker (only visible when category specific budget is checked)
            if (_isCategorySpecific) ...[
              Text(
                'CATEGORY',
                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
              ),
              VSpace.md,
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.large,
                  border: Border.all(color: AppColors.border),
                ),
                child: Builder(builder: (context) {
                  // Only allow expense-related categories for budgets
                  final categories = TransactionCategory.values.where((cat) {
                    return cat != TransactionCategory.salary &&
                        cat != TransactionCategory.freelance &&
                        cat != TransactionCategory.investment &&
                        cat != TransactionCategory.gift;
                  }).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;

                      return InkWell(
                        onTap: _isEditMode
                            ? null // Cannot change category of budget in edit mode for identifier persistence
                            : () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isSelected ? AppColors.accent : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                color: isSelected ? AppColors.accent : AppColors.secondaryText,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.name[0].toUpperCase() + category.name.substring(1),
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              VSpace.xl,
            ],

            PrimaryButton(
              text: _isEditMode ? 'Update Budget Limit' : 'Set Budget Limit',
              onPressed: isLoading ? null : _submitForm,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
