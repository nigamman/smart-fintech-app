import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/app_text_field.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final TransactionType initialType;
  final TransactionCategory? initialCategory;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialType = TransactionType.expense,
    this.initialCategory,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  late DateTime _selectedDate;
  late bool _isSplit;
  late final TextEditingController _splitWithController;
  late double _splitPercentage;
  late bool _isSplitPaid;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedType = tx?.type ?? widget.initialType;
    _selectedCategory = tx?.category ??
        widget.initialCategory ??
        (_selectedType == TransactionType.income ? TransactionCategory.salary : TransactionCategory.food);
    _selectedDate = tx?.transactionDate ?? DateTime.now();
    _isSplit = tx?.isSplit ?? false;
    _splitWithController = TextEditingController(text: tx?.splitWith ?? '');
    _splitPercentage = tx?.splitPercentage ?? 50.0;
    _isSplitPaid = tx?.isSplitPaid ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _splitWithController.dispose();
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

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    if (_isSplit && _selectedType == TransactionType.expense) {
      if (_splitWithController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a friend's name to split the bill")),
        );
        return;
      }
    }

    final notifier = ref.read(transactionControllerProvider.notifier);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      if (_isEditMode) {
        await notifier.updateTransaction(
          id: widget.transaction!.id,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory,
          note: _noteController.text.trim(),
          date: _selectedDate,
          createdAt: widget.transaction!.createdAt,
          isSplit: _selectedType == TransactionType.expense ? _isSplit : false,
          splitWith: _selectedType == TransactionType.expense && _isSplit ? _splitWithController.text.trim() : null,
          splitPercentage: _selectedType == TransactionType.expense && _isSplit ? _splitPercentage : 50.0,
          isSplitPaid: _selectedType == TransactionType.expense && _isSplit ? _isSplitPaid : false,
        );
      } else {
        await notifier.addTransaction(
          amount: amount,
          type: _selectedType,
          category: _selectedCategory,
          note: _noteController.text.trim(),
          date: _selectedDate,
          isSplit: _selectedType == TransactionType.expense ? _isSplit : false,
          splitWith: _selectedType == TransactionType.expense && _isSplit ? _splitWithController.text.trim() : null,
          splitPercentage: _selectedType == TransactionType.expense && _isSplit ? _splitPercentage : 50.0,
          isSplitPaid: _selectedType == TransactionType.expense && _isSplit ? _isSplitPaid : false,
        );
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Transaction updated successfully' : 'Transaction added successfully'),
        ),
      );
      router.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final notifier = ref.read(transactionControllerProvider.notifier);
                final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                final router = GoRouter.of(this.context);
                try {
                  await notifier.deleteTransaction(widget.transaction!.id);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Transaction deleted successfully')),
                  );
                  router.pop(); // Close screen
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error deleting transaction: $e')),
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
    final controllerState = ref.watch(transactionControllerProvider);
    final isLoading = controllerState.isLoading;

    final preferences = ref.watch(preferencesProvider);
    final currency = preferences.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
              onPressed: isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Display Container
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.large,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT',
                        style: AppTextStyles.label.copyWith(letterSpacing: 1.5),
                      ),
                      VSpace.xs,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currency,
                            style: AppTextStyles.display.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _amountController,
                              autofocus: !_isEditMode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter amount';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Enter valid number';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                fillColor: Colors.transparent,
                                filled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                VSpace.xl,

                // Transaction Type Toggle (Income / Expense)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.expense;
                            if (_selectedCategory == TransactionCategory.salary ||
                                _selectedCategory == TransactionCategory.freelance ||
                                _selectedCategory == TransactionCategory.investment ||
                                _selectedCategory == TransactionCategory.gift) {
                              _selectedCategory = TransactionCategory.food;
                            }
                          });
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _selectedType == TransactionType.expense
                                ? AppColors.expense.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: _selectedType == TransactionType.expense
                                  ? AppColors.expense
                                  : AppColors.border,
                              width: _selectedType == TransactionType.expense ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expense',
                            style: AppTextStyles.button.copyWith(
                              color: _selectedType == TransactionType.expense
                                  ? AppColors.expense
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    HSpace.md,
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.income;
                            if (_selectedCategory == TransactionCategory.food ||
                                _selectedCategory == TransactionCategory.shopping ||
                                _selectedCategory == TransactionCategory.travel ||
                                _selectedCategory == TransactionCategory.bills ||
                                _selectedCategory == TransactionCategory.entertainment ||
                                _selectedCategory == TransactionCategory.health ||
                                _selectedCategory == TransactionCategory.education) {
                              _selectedCategory = TransactionCategory.salary;
                            }
                          });
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _selectedType == TransactionType.income
                                ? AppColors.income.withValues(alpha: 0.12)
                                : AppColors.surface,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: _selectedType == TransactionType.income
                                  ? AppColors.income
                                  : AppColors.border,
                              width: _selectedType == TransactionType.income ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Income',
                            style: AppTextStyles.button.copyWith(
                              color: _selectedType == TransactionType.income
                                  ? AppColors.income
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                VSpace.xl,

                // Category Selection Section
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
                  child: Builder(
                    builder: (context) {
                      final categories = TransactionCategory.values.where((cat) {
                        if (_selectedType == TransactionType.income) {
                          return cat == TransactionCategory.salary ||
                              cat == TransactionCategory.freelance ||
                              cat == TransactionCategory.investment ||
                              cat == TransactionCategory.gift ||
                              cat == TransactionCategory.transfer ||
                              cat == TransactionCategory.other;
                        } else {
                          return cat == TransactionCategory.food ||
                              cat == TransactionCategory.shopping ||
                              cat == TransactionCategory.travel ||
                              cat == TransactionCategory.bills ||
                              cat == TransactionCategory.entertainment ||
                              cat == TransactionCategory.health ||
                              cat == TransactionCategory.education ||
                              cat == TransactionCategory.transfer ||
                              cat == TransactionCategory.other;
                        }
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
                            onTap: () {
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
                    }
                  ),
                ),
                VSpace.xl,

                // Date Picker Picker Tile
                Text(
                  'DATE',
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

                // Subcategory Field
                Text(
                  'SUBCATEGORY',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.md,
                AppTextField(
                  controller: _noteController,
                  label: 'e.g. Swiggy, Coffee, Rent',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a subcategory (e.g. Swiggy, Coffee)';
                    }
                    return null;
                  },
                ),

                // Split Bill Section (only for expense)
                if (_selectedType == TransactionType.expense) ...[
                  VSpace.xl,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.splitscreen_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Split this bill',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isSplit,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            setState(() {
                              _isSplit = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isSplit) ...[
                    VSpace.md,
                    AppTextField(
                      controller: _splitWithController,
                      label: "Friend's Name",
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                    ),
                    VSpace.md,
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Friend's Share: ${_splitPercentage.toStringAsFixed(0)}%",
                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Your Share: ${(100 - _splitPercentage).toStringAsFixed(0)}%",
                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Slider(
                            value: _splitPercentage,
                            min: 1,
                            max: 99,
                            divisions: 98,
                            activeColor: AppColors.accent,
                            inactiveColor: AppColors.border,
                            label: '${_splitPercentage.toStringAsFixed(0)}%',
                            onChanged: (val) {
                              setState(() {
                                _splitPercentage = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isEditMode) ...[
                      VSpace.md,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.medium,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Mark as Repaid / Settled",
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Checkbox(
                              value: _isSplitPaid,
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                setState(() {
                                  _isSplitPaid = val ?? false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
                VSpace.xxl,

                // Save Action Button
                PrimaryButton(
                  text: _isEditMode ? 'Save Changes' : 'Add Transaction',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _saveTransaction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
