import '../models/savings_goal_model.dart';

abstract class SavingsGoalRemoteDataSource {
  Future<void> saveGoal(SavingsGoalModel goal);
  Future<void> deleteGoal(String goalId);
  Stream<List<SavingsGoalModel>> getGoals(String userId);
}
