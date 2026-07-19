import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

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
  TransactionCategory? _selectedCategory;
  late int _selectedMonth;
  late int _selectedYear;

  bool get _isEditMode => widget.budget != null;

  final List<String> _monthsList = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<TransactionCategory> _expenseCategories = [
    TransactionCategory.food,
    TransactionCategory.bills,
    TransactionCategory.shopping,
    TransactionCategory.travel,
    TransactionCategory.entertainment,
    TransactionCategory.health,
    TransactionCategory.education,
    TransactionCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _amountController = TextEditingController(
      text: b != null ? b.limitAmount.toStringAsFixed(0) : '',
    );
    _selectedCategory = b?.category ?? TransactionCategory.food;
    final now = DateTime.now();
    _selectedMonth = b?.month ?? now.month;
    _selectedYear = b?.year ?? now.year;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant_rounded;
      case TransactionCategory.bills:
        return Icons.receipt_long_rounded;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TransactionCategory.travel:
        return Icons.directions_car_rounded;
      case TransactionCategory.entertainment:
        return Icons.movie_creation_outlined;
      case TransactionCategory.health:
        return Icons.medical_services_outlined;
      case TransactionCategory.education:
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getCategoryDisplayName(TransactionCategory category) {
    if (category == TransactionCategory.shopping) return 'Shop';
    return category.name[0].toUpperCase() + category.name.substring(1);
  }

  void _presentMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Month', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 250,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 12,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_monthsList[index], style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _selectedMonth = index + 1;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _presentYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - 2 + index);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Year', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 250,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: years.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(years[index].toString(), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _selectedYear = years[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
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

    final budget = Budget(
      id: widget.budget?.id ?? const Uuid().v4(),
      userId: user.id,
      limitAmount: amount,
      category: _selectedCategory,
      month: _selectedMonth,
      year: _selectedYear,
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(budgetControllerProvider.notifier).saveBudget(budget);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Category budget updated successfully' : 'Category budget saved successfully'),
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
          backgroundColor: AppColors.surface,
          title: const Text('Delete Budget Limit', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to permanently delete this budget limit?', style: TextStyle(color: Colors.white70)),
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
    final controllerState = ref.watch(budgetControllerProvider);
    final isLoading = controllerState.isLoading;
    final currency = ref.watch(preferencesProvider).currency;

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
                    _isEditMode ? 'Edit budget' : 'Add budget',
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
                          tooltip: 'Delete Budget Limit',
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

              // CATEGORY field
              Text(
                'CATEGORY',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.disabledText,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _expenseCategories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.2 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              color: isSelected ? AppColors.primary : AppColors.primaryText,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getCategoryDisplayName(cat),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : AppColors.disabledText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                          if (double.tryParse(val) == null || double.parse(val) <= 0) {
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
                          setState(() {}); // refresh width dynamically
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // "Monthly limit for this category" subtitle
              Center(
                child: Text(
                  'Monthly limit for this category',
                  style: AppTextStyles.monoSecondary.copyWith(
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Month Selector Row
              GestureDetector(
                onTap: _presentMonthPicker,
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
                        'Month',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _monthsList[_selectedMonth - 1],
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

              // Year Selector Row
              GestureDetector(
                onTap: _presentYearPicker,
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
                        'Year',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _selectedYear.toString(),
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

              // Save budget Action Button
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
                    _isEditMode ? 'Save changes' : 'Save budget',
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
