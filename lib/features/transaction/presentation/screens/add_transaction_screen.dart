import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../commons/widgets/app_text_field.dart';
import '../../../../core/utils/thousands_formatter.dart';
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
  late List<String> _splitFriends;
  late bool _isSplitPaid;
  late bool _isOthersSelected;
  bool _isAddingFriend = false;
  final TextEditingController _newFriendController = TextEditingController();
  
  late final ScrollController _categoryScrollController;
  late final ScrollController _subcategoryScrollController;
  Timer? _scrollHintTimer;

  bool get _isEditMode => widget.transaction != null;

  String _formatAmount(double val) {
    return NumberFormat('#,##0', 'en_US').format(val.abs());
  }

  void _triggerScrollHint() {
    if (!mounted) return;

    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        45.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          if (_categoryScrollController.hasClients) {
            _categoryScrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }

    if (_subcategoryScrollController.hasClients) {
      _subcategoryScrollController.animateTo(
        40.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          if (_subcategoryScrollController.hasClients) {
            _subcategoryScrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryScrollController = ScrollController();
    _subcategoryScrollController = ScrollController();
    
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
    
    // Parse list of friends from splitWith comma-separated string
    if (tx?.splitWith != null && tx!.splitWith!.trim().isNotEmpty) {
      _splitFriends = tx.splitWith!.split(', ').where((s) => s.trim().isNotEmpty).map((s) => s.replaceAll('[PAID]', '').trim()).toList();
    } else {
      _splitFriends = ['Aakash Kumar', 'Priya Sharma'];
    }
    _isSplitPaid = tx?.isSplitPaid ?? false;

    final txNote = tx?.note ?? '';
    final defaultSubs = _getSubcategories(_selectedCategory);
    if (txNote.isNotEmpty && !defaultSubs.any((s) => s.toLowerCase() == txNote.toLowerCase())) {
      _isOthersSelected = true;
    } else {
      _isOthersSelected = false;
    }

    // Run initial peek scroll hint animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), _triggerScrollHint);
    });

    // Setup periodic repeat peek scroll hint animation (every 8 seconds)
    _scrollHintTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _triggerScrollHint();
    });
  }

  @override
  void dispose() {
    _scrollHintTimer?.cancel();
    _amountController.dispose();
    _noteController.dispose();
    _newFriendController.dispose();
    _categoryScrollController.dispose();
    _subcategoryScrollController.dispose();
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
        return Icons.shopping_cart_rounded;
      case TransactionCategory.travel:
        return Icons.flight_takeoff_rounded;
      case TransactionCategory.bills:
        return Icons.home_rounded;
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

  List<String> _getSubcategories(TransactionCategory category) {
    List<String> subs;
    switch (category) {
      case TransactionCategory.bills:
        subs = ['Rent', 'Electricity', 'Water', 'Internet', 'Gas'];
        break;
      case TransactionCategory.food:
        subs = ['Groceries', 'Dine out', 'Delivery', 'Coffee'];
        break;
      case TransactionCategory.travel:
        subs = ['Fuel', 'Uber/Cab', 'Flights', 'Transit'];
        break;
      case TransactionCategory.shopping:
        subs = ['Clothes', 'Electronics', 'Home', 'Gifts'];
        break;
      case TransactionCategory.salary:
        subs = ['Paycheck', 'Bonus', 'Overtime'];
        break;
      case TransactionCategory.freelance:
        subs = ['Contract', 'Consulting', 'One-off'];
        break;
      case TransactionCategory.investment:
        subs = ['Dividends', 'Stock Sale', 'Crypto', 'Real Estate'];
        break;
      case TransactionCategory.gift:
        subs = ['Birthday', 'Holiday', 'Family'];
        break;
      default:
        subs = ['General', 'Utilities', 'Other'];
    }
    // Append 'Others' if not present
    if (!subs.contains('Others')) {
      subs.add('Others');
    }
    return subs;
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
            colorScheme: ColorScheme.dark(
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

  void _saveTransaction() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose or type a subcategory note')),
      );
      return;
    }

    if (_isSplit && _selectedType == TransactionType.expense && _splitFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one friends to split with')),
      );
      return;
    }

    final notifier = ref.read(transactionControllerProvider.notifier);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Compute split shares: percentage is (friends count / total splitters) * 100
    final double splitPercentage = _isSplit && _selectedType == TransactionType.expense
        ? (_splitFriends.length / (1.0 + _splitFriends.length)) * 100.0
        : 50.0;

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
          splitWith: _selectedType == TransactionType.expense && _isSplit ? _splitFriends.join(', ') : null,
          splitPercentage: splitPercentage,
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
          splitWith: _selectedType == TransactionType.expense && _isSplit ? _splitFriends.join(', ') : null,
          splitPercentage: splitPercentage,
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
          backgroundColor: AppColors.surface,
          title: Text('Delete Transaction', style: AppTextStyles.title),
          content: Text('Are you sure you want to delete this transaction?', style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.primary)),
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
              child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
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
    final currency = ref.watch(preferencesProvider).currency;

    final double enteredAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    
    // Split computations
    final int totalSplitters = 1 + _splitFriends.length;
    final double individualShare = enteredAmount / totalSplitters;
    final double friendsOwe = enteredAmount - individualShare;

    final subcategories = _getSubcategories(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditMode ? 'Edit transaction' : 'Add transaction',
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    BouncyButton(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Expense / Income Toggle Row
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedType = TransactionType.expense;
                            _isOthersSelected = false;
                            if (_selectedCategory == TransactionCategory.salary ||
                                _selectedCategory == TransactionCategory.freelance ||
                                _selectedCategory == TransactionCategory.investment ||
                                _selectedCategory == TransactionCategory.gift) {
                              _selectedCategory = TransactionCategory.food;
                            }
                            _noteController.clear();
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.expense ? AppColors.expense : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Expense',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _selectedType == TransactionType.expense ? AppColors.primaryText : AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedType = TransactionType.income;
                            _isOthersSelected = false;
                            if (_selectedCategory == TransactionCategory.food ||
                                _selectedCategory == TransactionCategory.shopping ||
                                _selectedCategory == TransactionCategory.travel ||
                                _selectedCategory == TransactionCategory.bills ||
                                _selectedCategory == TransactionCategory.entertainment ||
                                _selectedCategory == TransactionCategory.health ||
                                _selectedCategory == TransactionCategory.education) {
                              _selectedCategory = TransactionCategory.salary;
                            }
                            _noteController.clear();
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.income ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _selectedType == TransactionType.income ? AppColors.background : AppColors.primaryText,
                                fontSize: 13,
                              ),
                            ),
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
                        child: TextField(
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

                // CATEGORY Header & List
                Text(
                  'CATEGORY',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.disabledText,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Horizontal category cards list
                SingleChildScrollView(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: TransactionCategory.values.where((cat) {
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
                    }).map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                              _noteController.clear();
                              _isOthersSelected = false;
                            });
                          },
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getCategoryIcon(cat),
                                  color: isSelected ? AppColors.primary : AppColors.secondaryText,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.name[0].toUpperCase() + cat.name.substring(1),
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primaryText : AppColors.disabledText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Date selector Card
                GestureDetector(
                  onTap: _presentDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.disabledText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: AppTextStyles.mono.copyWith(
                            fontSize: 13,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SUBCATEGORY Chips
                Text(
                  'SUBCATEGORY',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.disabledText,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal chips layout
                SingleChildScrollView(
                  controller: _subcategoryScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: subcategories.map((sub) {
                      final isOthers = sub.toLowerCase() == 'others';
                      final isSelected = isOthers
                          ? _isOthersSelected
                          : (_noteController.text.trim().toLowerCase() == sub.toLowerCase() && !_isOthersSelected);
                          
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            sub,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 11,
                              color: isSelected ? AppColors.background : AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                if (isOthers) {
                                  _isOthersSelected = true;
                                  _noteController.clear();
                                } else {
                                  _isOthersSelected = false;
                                  _noteController.text = sub;
                                }
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Custom Note / Subcategory Text Field (Only visible when Others is selected)
                if (_isOthersSelected) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _noteController,
                    label: 'Enter custom subcategory/note',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ],
                const SizedBox(height: 24),

                // SPLIT expense toggle (Only for expenses)
                if (_selectedType == TransactionType.expense) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Split this expense',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Divide the amount with friends',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isSplit,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isSplit = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Split detailed panel card
                  if (_isSplit) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. You Share row
                          _buildSplitMemberRow('You', 'Y', individualShare, currency),
                          const Divider(height: 16, color: AppColors.border),

                          // 2. Friends split rows
                          ..._splitFriends.map((friend) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppColors.disabledText, width: 0.8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              friend.isNotEmpty ? friend[0].toUpperCase() : 'F',
                                              style: TextStyle(fontSize: 9, color: AppColors.disabledText, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          friend,
                                          style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$currency${_formatAmount(individualShare)}',
                                          style: AppTextStyles.mono.copyWith(fontSize: 12),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.expense),
                                          onPressed: () {
                                            setState(() {
                                              _splitFriends.remove(friend);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 16, color: AppColors.border),
                              ],
                            );
                          }),

                          // 3. Add Friend Inline Text Field
                          if (_isAddingFriend)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _newFriendController,
                                    autofocus: true,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    cursorColor: AppColors.primary,
                                    decoration: InputDecoration(
                                      hintText: 'Enter friend name',
                                      hintStyle: const TextStyle(color: AppColors.disabledText, fontSize: 12),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: AppColors.border, width: 0.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                                      ),
                                    ),
                                    onFieldSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        setState(() {
                                          _splitFriends.add(val.trim());
                                          _newFriendController.clear();
                                          _isAddingFriend = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (_newFriendController.text.trim().isNotEmpty) {
                                      setState(() {
                                        _splitFriends.add(_newFriendController.text.trim());
                                        _newFriendController.clear();
                                        _isAddingFriend = false;
                                      });
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Icon(Icons.check, color: AppColors.income, size: 20),
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      _isAddingFriend = false;
                                      _newFriendController.clear();
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Icon(Icons.close, color: AppColors.expense, size: 20),
                                  ),
                                ),
                              ],
                            )
                          else
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isAddingFriend = true;
                                  });
                                },
                                child: Text(
                                  '+ Add another friend',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          const Divider(height: 16, color: AppColors.border, thickness: 1.0),
                          const SizedBox(height: 8),

                          // 4. Shares Summary Metrics columns
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$currency${_formatAmount(individualShare)}',
                                      style: AppTextStyles.mono.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'YOUR SHARE',
                                      style: AppTextStyles.label.copyWith(fontSize: 8.5, color: AppColors.disabledText),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 24, width: 0.5, color: AppColors.border),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$currency${_formatAmount(friendsOwe)}',
                                      style: AppTextStyles.mono.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'FRIENDS OWE',
                                      style: AppTextStyles.label.copyWith(fontSize: 8.5, color: AppColors.disabledText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Inline split paid option (Only in edit mode)
                    if (_isEditMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Mark as Repaid / Settled",
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            Checkbox(
                              value: _isSplitPaid,
                              activeColor: AppColors.primary,
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
                const SizedBox(height: 32),

                // Save button
                BouncyButton(
                  onTap: isLoading ? null : _saveTransaction,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isEditMode ? 'Save changes' : 'Save transaction',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Inline Delete Button (Only in edit mode)
                if (_isEditMode) ...[
                  const SizedBox(height: 14),
                  BouncyButton(
                    onTap: isLoading ? null : _confirmDelete,
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.expense.withOpacity(0.5), width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Delete transaction',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitMemberRow(String name, String initial, double amount, String currency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.disabledText, width: 0.8),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(fontSize: 9, color: AppColors.disabledText, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          '$currency${_formatAmount(amount)}',
          style: AppTextStyles.mono.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
