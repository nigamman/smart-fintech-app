import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource _remoteDataSource;

  BudgetRepositoryImpl({
    required BudgetRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<void> saveBudget(Budget budget) async {
    final model = BudgetModel(
      id: budget.id,
      userId: budget.userId,
      limitAmount: budget.limitAmount,
      category: budget.category,
      month: budget.month,
      year: budget.year,
      createdAt: budget.createdAt,
    );
    await _remoteDataSource.saveBudget(model);
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await _remoteDataSource.deleteBudget(budgetId);
  }

  @override
  Stream<List<Budget>> getBudgets(String userId, int month, int year) {
    return _remoteDataSource.getBudgets(userId, month, year);
  }
}
