import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../data/datasources/budget_remote_datasource.dart';
import '../../data/datasources/budget_remote_datasource_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>((ref) {
  return BudgetRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    remoteDataSource: ref.watch(budgetRemoteDataSourceProvider),
  );
});

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }
  final now = DateTime.now();
  return ref.watch(budgetRepositoryProvider).getBudgets(user.id, now.month, now.year);
});

class CategoryBudgetProgress {
  final String budgetId;
  final TransactionCategory category;
  final double limit;
  final double spent;

  double get remaining => limit - spent;
  double get progressPercentage => limit > 0 ? spent / limit : 0;
  bool get isWarning80 => progressPercentage >= 0.8 && progressPercentage < 1.0;
  bool get isExceeded => progressPercentage >= 1.0;

  const CategoryBudgetProgress({
    required this.budgetId,
    required this.category,
    required this.limit,
    required this.spent,
  });
}

class MonthlyBudgetProgress {
  final Budget? monthlyBudget;
  final double totalLimit;
  final double totalSpent;
  final List<CategoryBudgetProgress> categoryProgresses;

  double get remaining => totalLimit - totalSpent;
  double get progressPercentage => totalLimit > 0 ? totalSpent / totalLimit : 0;
  bool get isWarning80 => progressPercentage >= 0.8 && progressPercentage < 1.0;
  bool get isExceeded => progressPercentage >= 1.0;

  const MonthlyBudgetProgress({
    this.monthlyBudget,
    required this.totalLimit,
    required this.totalSpent,
    required this.categoryProgresses,
  });
}

final budgetProgressProvider = Provider<AsyncValue<MonthlyBudgetProgress>>((ref) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return budgetsAsync.when(
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
    data: (budgets) {
      return transactionsAsync.when(
        loading: () => const AsyncLoading(),
        error: (err, stack) => AsyncError(err, stack),
        data: (transactions) {
          final now = DateTime.now();
          // Filter current month's expenses
          final currentMonthExpenses = transactions.where((tx) {
            return tx.type == TransactionType.expense &&
                tx.transactionDate.month == now.month &&
                tx.transactionDate.year == now.year;
          }).toList();

          // Calculate total spent
          double totalSpent = 0.0;
          for (final tx in currentMonthExpenses) {
            totalSpent += tx.amount;
          }

          // Find overall monthly budget (where category == null)
          final overallBudget = budgets.cast<Budget?>().firstWhere(
                (b) => b?.category == null,
                orElse: () => null,
              );

          final totalLimit = overallBudget?.limitAmount ?? 0.0;

          // Group expenses by category
          final categoryExpenses = <TransactionCategory, double>{};
          for (final tx in currentMonthExpenses) {
            categoryExpenses[tx.category] = (categoryExpenses[tx.category] ?? 0.0) + tx.amount;
          }

          // Build category budget progress list
          final categoryProgresses = <CategoryBudgetProgress>[];
          for (final budget in budgets) {
            if (budget.category != null) {
              final spent = categoryExpenses[budget.category!] ?? 0.0;
              categoryProgresses.add(
                CategoryBudgetProgress(
                  budgetId: budget.id,
                  category: budget.category!,
                  limit: budget.limitAmount,
                  spent: spent,
                ),
              );
            }
          }

          return AsyncData(
            MonthlyBudgetProgress(
              monthlyBudget: overallBudget,
              totalLimit: totalLimit,
              totalSpent: totalSpent,
              categoryProgresses: categoryProgresses,
            ),
          );
        },
      );
    },
  );
});

final budgetControllerProvider = AsyncNotifierProvider<BudgetController, void>(
  BudgetController.new,
);

class BudgetController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveBudget(Budget budget) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).saveBudget(budget);
      ref.invalidate(dashboardDataProvider);
    });
  }

  Future<void> deleteBudget(String budgetId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).deleteBudget(budgetId);
      ref.invalidate(dashboardDataProvider);
    });
  }
}
