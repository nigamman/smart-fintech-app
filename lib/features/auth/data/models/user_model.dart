import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.monthlyIncome,
    required super.monthlySavingsGoal,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
      monthlySavingsGoal:
      (json['monthlySavingsGoal'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'monthlyIncome': monthlyIncome,
      'monthlySavingsGoal': monthlySavingsGoal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? monthlyIncome,
    double? monthlySavingsGoal,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlySavingsGoal:
      monthlySavingsGoal ?? this.monthlySavingsGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}