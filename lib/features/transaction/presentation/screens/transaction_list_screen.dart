import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/app_text_field.dart';
import '../../../../commons/widgets/empty_state.dart';
import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategoryFilterSheet() {
    final filters = ref.read(transactionFiltersProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Category',
                      style: AppTextStyles.h3,
                    ),
                    if (filters.category != null)
                      TextButton(
                        onPressed: () {
                          ref.read(transactionFiltersProvider.notifier).updateFilters(
                                (state) => state.copyWith(clearCategory: true),
                              );
                          Navigator.pop(context);
                        },
                        child: const Text('Clear Filter'),
                      ),
                  ],
                ),
                VSpace.md,
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: TransactionCategory.values.length,
                    itemBuilder: (context, index) {
                      final cat = TransactionCategory.values[index];
                      final isSelected = filters.category == cat;

                      return InkWell(
                        onTap: () {
                          ref.read(transactionFiltersProvider.notifier).updateFilters(
                                (state) => state.copyWith(category: cat),
                              );
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat.name[0].toUpperCase() + cat.name.substring(1),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.primaryText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDateRangeFilter() async {
    final filters = ref.read(transactionFiltersProvider);
    final initialRange = filters.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400.0,
                  maxHeight: 520.0,
                ),
                child: child!,
              ),
            ],
          ),
        );
      },
    );

    if (pickedRange != null) {
      ref.read(transactionFiltersProvider.notifier).updateFilters(
            (state) => state.copyWith(dateRange: pickedRange),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredTransactionsProvider);
    final filters = ref.watch(transactionFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Calendar View',
            onPressed: () => context.push('/calendar'),
          ),
          IconButton(
            icon: Icon(
              Icons.category_outlined,
              color: filters.category != null ? AppColors.accent : null,
            ),
            tooltip: 'Filter Category',
            onPressed: _showCategoryFilterSheet,
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: filters.dateRange != null ? AppColors.accent : null,
            ),
            tooltip: 'Select Date Range',
            onPressed: _showDateRangeFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Panel
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                // Search Field
                AppTextField(
                  controller: _searchController,
                  label: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(transactionFiltersProvider.notifier).updateFilters(
                                  (state) => state.copyWith(searchQuery: ''),
                                );
                          },
                        )
                      : null,
                  onChanged: (val) {
                    ref.read(transactionFiltersProvider.notifier).updateFilters(
                          (state) => state.copyWith(searchQuery: val),
                        );
                  },
                ),
                VSpace.md,

                // Quick Filters Row (Type, Category, Date)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type: ALL
                      ChoiceChip(
                        label: const Text('All'),
                        selected: filters.type == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(transactionFiltersProvider.notifier).updateFilters(
                                  (state) => state.copyWith(clearType: true),
                                );
                          }
                        },
                      ),
                      HSpace.sm,

                      // Type: INCOME
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: filters.type == TransactionType.income,
                        selectedColor: AppColors.income.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(transactionFiltersProvider.notifier).updateFilters(
                                  (state) => state.copyWith(type: TransactionType.income),
                                );
                          }
                        },
                      ),
                      HSpace.sm,

                      // Type: EXPENSE
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: filters.type == TransactionType.expense,
                        selectedColor: AppColors.expense.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(transactionFiltersProvider.notifier).updateFilters(
                                  (state) => state.copyWith(type: TransactionType.expense),
                                );
                          }
                        },
                      ),


                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: filteredAsync.when(
              loading: () => const LoadingIndicator(),
              error: (err, stack) => Center(
                child: Text('Error loading transactions: $err'),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const EmptyState(
                    title: 'No Transactions Found',
                    subtitle: 'Try adjusting your search query or filter settings.',
                    icon: Icons.search_off_outlined,
                  );
                }

                // Group transactions by date
                final grouped = <String, List<Transaction>>{};
                for (final tx in transactions) {
                  final key = DateFormat('EEEE, dd MMMM yyyy').format(tx.transactionDate);
                  grouped.putIfAbsent(key, () => []).add(tx);
                }

                final groupKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: groupKeys.length,
                  itemBuilder: (context, index) {
                    final dateKey = groupKeys[index];
                    final dateTxs = grouped[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 8),
                          child: Text(
                            dateKey,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.large,
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dateTxs.length,
                            separatorBuilder: (context, i) => const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, i) {
                              final tx = dateTxs[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: TransactionTile(
                                  title: tx.note != null && tx.note!.isNotEmpty
                                      ? tx.note!
                                      : tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                                  category: tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                                  amount: tx.amount,
                                  date: tx.transactionDate,
                                  type: tx.type,
                                  onTap: () => _showTransactionActions(context, tx),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showTransactionActions(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/add-transaction', extra: transaction);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
                title: const Text('Delete Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, transaction.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String transactionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to permanently delete this transaction?'),
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
                  await ref.read(transactionControllerProvider.notifier).deleteTransaction(transactionId);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Transaction deleted successfully')),
                  );
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
}
