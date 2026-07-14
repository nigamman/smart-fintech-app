import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/empty_state.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../providers/calendar_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  void _showTransactionActions(BuildContext context, WidgetRef ref, Transaction transaction) {
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
                  _confirmDelete(context, ref, transaction.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String transactionId) {
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
                final scaffoldMessenger = ScaffoldMessenger.of(context);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigatedMonth = ref.watch(calendarMonthProvider);
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final dailyTransactions = ref.watch(calendarDailyTransactionsProvider);
    final dailyTotals = ref.watch(calendarDailyTotalsProvider);
    final monthTransactionsGrouped = ref.watch(calendarMonthTransactionsProvider);

    final monthStr = DateFormat('MMMM yyyy').format(navigatedMonth);

    // Compute Calendar Days
    final firstDayOfMonth = DateTime(navigatedMonth.year, navigatedMonth.month, 1);
    final offset = firstDayOfMonth.weekday - 1; // 0 for Mon, 1 for Tue, etc.
    final daysInMonth = DateTime(navigatedMonth.year, navigatedMonth.month + 1, 0).day;
    final totalRows = ((offset + daysInMonth) / 7).ceil();
    final totalCells = totalRows * 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          // Month Swiper Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    ref.read(calendarMonthProvider.notifier).previousMonth();
                  },
                ),
                Text(
                  monthStr,
                  style: AppTextStyles.h3,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    ref.read(calendarMonthProvider.notifier).nextMonth();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Calendar Section (Grid + Weekdays)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Weekdays Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
                    return SizedBox(
                      width: 40,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Day Cells Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    final cellDate = DateTime(
                      navigatedMonth.year,
                      navigatedMonth.month,
                      1 - offset + index,
                    );
                    final isCurrentMonth = cellDate.month == navigatedMonth.month;
                    final isSelected = cellDate.day == selectedDate.day &&
                        cellDate.month == selectedDate.month &&
                        cellDate.year == selectedDate.year;

                    // Fetch transactions on this date for indicator dots
                    final dayTxs = isCurrentMonth
                        ? monthTransactionsGrouped[cellDate.day] ?? []
                        : <Transaction>[];
                    final hasIncome = dayTxs.any((tx) => tx.type == TransactionType.income);
                    final hasExpense = dayTxs.any((tx) => tx.type == TransactionType.expense);

                    return InkWell(
                      onTap: () {
                        ref.read(calendarSelectedDateProvider.notifier).selectDate(cellDate);
                        if (cellDate.month != navigatedMonth.month) {
                          ref.read(calendarMonthProvider.notifier).setMonth(cellDate);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${cellDate.day}',
                              style: AppTextStyles.body.copyWith(
                                color: isSelected
                                    ? AppColors.white
                                    : (isCurrentMonth
                                        ? AppColors.primaryText
                                        : AppColors.secondaryText.withValues(alpha: 0.5)),
                                fontWeight: isSelected || (isCurrentMonth && cellDate.day == DateTime.now().day && cellDate.month == DateTime.now().month)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            // Dot indicators
                            if (dayTxs.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasIncome)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? AppColors.white : AppColors.income,
                                      ),
                                    ),
                                  if (hasIncome && hasExpense) const SizedBox(width: 2),
                                  if (hasExpense)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? AppColors.white : AppColors.expense,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Daily Transactions Section
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
                      style: AppTextStyles.h3,
                    ),
                  ),
                  // Daily Income / Expense stats card
                  if (dailyTransactions.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income',
                                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+₹${dailyTotals.income.toStringAsFixed(0)}',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.income,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Expenses',
                                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '-₹${dailyTotals.expense.toStringAsFixed(0)}',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.expense,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Net Total',
                                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dailyTotals.net >= 0 ? '+' : ''}₹${dailyTotals.net.toStringAsFixed(0)}',
                                style: AppTextStyles.body.copyWith(
                                  color: dailyTotals.net >= 0 ? AppColors.income : AppColors.expense,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    VSpace.md,
                  ],

                  // Day Transactions List
                  Expanded(
                    child: dailyTransactions.isEmpty
                        ? const EmptyState(
                            title: 'No Transactions',
                            subtitle: 'Tap the button below to add a transaction for this day.',
                            icon: Icons.assignment_turned_in_outlined,
                          )
                        : ListView.separated(
                            itemCount: dailyTransactions.length,
                            separatorBuilder: (context, i) => const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, i) {
                              final tx = dailyTransactions[i];
                              return TransactionTile(
                                title: tx.note != null && tx.note!.isNotEmpty
                                    ? tx.note!
                                    : tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                                category: tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                                amount: tx.amount,
                                date: tx.transactionDate,
                                type: tx.type,
                                onTap: () => _showTransactionActions(context, ref, tx),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
