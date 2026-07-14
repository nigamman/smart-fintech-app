import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';

class CalendarMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void setMonth(DateTime date) {
    state = DateTime(date.year, date.month, 1);
  }
}

final calendarMonthProvider = NotifierProvider<CalendarMonthNotifier, DateTime>(
  CalendarMonthNotifier.new,
);

class CalendarSelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final calendarSelectedDateProvider = NotifierProvider<CalendarSelectedDateNotifier, DateTime>(
  CalendarSelectedDateNotifier.new,
);

final calendarDailyTransactionsProvider = Provider<List<Transaction>>((ref) {
  final selectedDate = ref.watch(calendarSelectedDateProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.maybeWhen(
    data: (txs) {
      return txs.where((tx) {
        return tx.transactionDate.day == selectedDate.day &&
            tx.transactionDate.month == selectedDate.month &&
            tx.transactionDate.year == selectedDate.year;
      }).toList();
    },
    orElse: () => [],
  );
});

class DailyTotals {
  final double income;
  final double expense;
  double get net => income - expense;

  const DailyTotals({
    required this.income,
    required this.expense,
  });
}

final calendarDailyTotalsProvider = Provider<DailyTotals>((ref) {
  final txs = ref.watch(calendarDailyTransactionsProvider);
  double income = 0.0;
  double expense = 0.0;

  for (final tx in txs) {
    if (tx.type == TransactionType.income) {
      income += tx.amount;
    } else {
      expense += tx.amount;
    }
  }

  return DailyTotals(income: income, expense: expense);
});

final calendarMonthTransactionsProvider = Provider<Map<int, List<Transaction>>>((ref) {
  final navigatedMonth = ref.watch(calendarMonthProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.maybeWhen(
    data: (txs) {
      final grouped = <int, List<Transaction>>{};
      for (final tx in txs) {
        if (tx.transactionDate.month == navigatedMonth.month &&
            tx.transactionDate.year == navigatedMonth.year) {
          grouped.putIfAbsent(tx.transactionDate.day, () => []).add(tx);
        }
      }
      return grouped;
    },
    orElse: () => {},
  );
});
