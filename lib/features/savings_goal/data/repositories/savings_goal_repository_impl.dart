import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../datasources/savings_goal_remote_datasource.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final SavingsGoalRemoteDataSource _remoteDataSource;

  SavingsGoalRepositoryImpl({
    required SavingsGoalRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<void> saveGoal(SavingsGoal goal) async {
    final model = SavingsGoalModel(
      id: goal.id,
      userId: goal.userId,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      createdAt: goal.createdAt,
    );
    await _remoteDataSource.saveGoal(model);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _remoteDataSource.deleteGoal(goalId);
  }

  @override
  Stream<List<SavingsGoal>> getGoals(String userId) {
    return _remoteDataSource.getGoals(userId);
  }
}
