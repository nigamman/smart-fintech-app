import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';

class AnalyticsDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void setDate(DateTime date) {
    state = date;
  }
}

final analyticsDateProvider = NotifierProvider<AnalyticsDateNotifier, DateTime>(
  AnalyticsDateNotifier.new,
);

class MonthlyCategoryExpense {
  final TransactionCategory category;
  final double amount;
  final double percentage;

  const MonthlyCategoryExpense({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class MonthTrendItem {
  final String label; // e.g. "Jan"
  final int month;
  final int year;
  final double income;
  final double expense;
  double get savings => income - expense;

  const MonthTrendItem({
    required this.label,
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
  });
}

class AnalyticsData {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  double get netSavings => totalIncome - totalExpense;

  final List<MonthlyCategoryExpense> categoryBreakdown;
  final List<MonthTrendItem> monthlyTrends;

  final TransactionCategory? highestSpendingCategory;
  final double highestSpendingAmount;
  final double averageDailySpending;

  const AnalyticsData({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
    required this.monthlyTrends,
    this.highestSpendingCategory,
    required this.highestSpendingAmount,
    required this.averageDailySpending,
  });
}

final analyticsDataProvider = Provider<AsyncValue<AnalyticsData>>((ref) {
  final selectedDate = ref.watch(analyticsDateProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.when(
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
    data: (transactions) {
      final targetMonth = selectedDate.month;
      final targetYear = selectedDate.year;

      // 1. Calculate Monthly Stats
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      final categoryExpenses = <TransactionCategory, double>{};

      for (final tx in transactions) {
        if (tx.transactionDate.month == targetMonth && tx.transactionDate.year == targetYear) {
          if (tx.type == TransactionType.income) {
            totalIncome += tx.amount;
          } else {
            double expenseAmount = tx.amount;
            if (tx.isSplit) {
              final share = tx.splitPercentage ?? 50.0;
              expenseAmount -= (tx.amount * (share / 100));
            }
            totalExpense += expenseAmount;
            categoryExpenses[tx.category] = (categoryExpenses[tx.category] ?? 0.0) + expenseAmount;
          }
        }
      }

      // 2. Build Category Breakdown
      final categoryBreakdown = <MonthlyCategoryExpense>[];
      categoryExpenses.forEach((cat, amt) {
        final pct = totalExpense > 0 ? amt / totalExpense : 0.0;
        categoryBreakdown.add(
          MonthlyCategoryExpense(category: cat, amount: amt, percentage: pct),
        );
      });
      // Sort breakdown descending by amount
      categoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));

      // 3. Find Highest Spending Category
      TransactionCategory? highestCategory;
      double highestAmount = 0.0;
      if (categoryBreakdown.isNotEmpty) {
        highestCategory = categoryBreakdown.first.category;
        highestAmount = categoryBreakdown.first.amount;
      }

      // 4. Calculate Average Daily Spending
      final now = DateTime.now();
      int days = 30;
      if (targetMonth == now.month && targetYear == now.year) {
        days = now.day;
      } else {
        // Find total days in the target month
        days = DateTime(targetYear, targetMonth + 1, 0).day;
      }
      final averageDailySpending = days > 0 ? totalExpense / days : 0.0;

      // 5. Historical Trends: Last 6 Months leading up to selected date
      final monthlyTrends = <MonthTrendItem>[];
      final monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      for (int i = 5; i >= 0; i--) {
        final date = DateTime(targetYear, targetMonth - i, 1);
        final m = date.month;
        final y = date.year;

        double mIncome = 0.0;
        double mExpense = 0.0;

        for (final tx in transactions) {
          if (tx.transactionDate.month == m && tx.transactionDate.year == y) {
            if (tx.type == TransactionType.income) {
              mIncome += tx.amount;
            } else {
              double expenseAmount = tx.amount;
              if (tx.isSplit) {
                final share = tx.splitPercentage ?? 50.0;
                expenseAmount -= (tx.amount * (share / 100));
              }
              mExpense += expenseAmount;
            }
          }
        }

        monthlyTrends.add(
          MonthTrendItem(
            label: '${monthLabels[m - 1]} ${y % 100}',
            month: m,
            year: y,
            income: mIncome,
            expense: mExpense,
          ),
        );
      }

      return AsyncData(
        AnalyticsData(
          month: targetMonth,
          year: targetYear,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          categoryBreakdown: categoryBreakdown,
          monthlyTrends: monthlyTrends,
          highestSpendingCategory: highestCategory,
          highestSpendingAmount: highestAmount,
          averageDailySpending: averageDailySpending,
        ),
      );
    },
  );
});
