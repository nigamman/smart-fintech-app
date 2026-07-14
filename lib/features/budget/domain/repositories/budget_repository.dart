import '../../domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<void> saveBudget(Budget budget);
  Future<void> deleteBudget(String budgetId);
  Stream<List<Budget>> getBudgets(String userId, int month, int year);
}
