class AppUser {
  final String id;
  final String name;
  final String email;
  final double monthlyIncome;
  final double monthlySavingsGoal;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.monthlyIncome,
    required this.monthlySavingsGoal,
    required this.createdAt,
  });
}