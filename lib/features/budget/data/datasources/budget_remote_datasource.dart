import '../models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String budgetId);
  Stream<List<BudgetModel>> getBudgets(String userId, int month, int year);
}
