import '../../domain/entities/savings_goal.dart';

abstract class SavingsGoalRepository {
  Future<void> saveGoal(SavingsGoal goal);
  Future<void> deleteGoal(String goalId);
  Stream<List<SavingsGoal>> getGoals(String userId);
}
