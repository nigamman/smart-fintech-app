import '../../../transaction/data/models/transaction_model.dart';

class DashboardData {
  final String userName;
  final double monthlyIncome;
  final double monthlySavingsGoal;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final double safeToSpend;
  final double monthlyExpense;
  final List<TransactionModel> recentTransactions;

  const DashboardData({
    required this.userName,
    required this.monthlyIncome,
    required this.monthlySavingsGoal,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.safeToSpend,
    required this.monthlyExpense,
    required this.recentTransactions,
  });
}