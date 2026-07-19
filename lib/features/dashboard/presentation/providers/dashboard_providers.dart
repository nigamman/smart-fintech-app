import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/datasources/dashboard_remote_datasource_impl.dart';
import '../../data/repositories/dashboard_repositories.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../../../core/services/home_widget_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
  );
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  // Automatically watch transactions stream to trigger refreshes when a transaction is added/modified
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final transactions = transactionsAsync.value ?? [];
  
  // Watch profile to automatically trigger refreshes on profile changes
  final userAsync = ref.watch(userProfileStreamProvider);
  final user = userAsync.value;

  if (user == null) {
    return DashboardData(
      userName: '',
      monthlyIncome: 0.0,
      monthlySavingsGoal: 0.0,
      totalIncome: 0.0,
      totalExpense: 0.0,
      totalBalance: 0.0,
      safeToSpend: 0.0,
      recentTransactions: [],
    );
  }

  double totalIncome = 0;
  double totalExpense = 0;

  for (final transaction in transactions) {
    if (transaction.isEncrypted) continue;

    if (transaction.type == TransactionType.income) {
      totalIncome += transaction.amount;
    } else {
      double expenseAmount = transaction.amount;
      if (transaction.isSplit) {
        final share = transaction.splitPercentage ?? 50.0;
        expenseAmount -= (transaction.amount * (share / 100));
      }
      totalExpense += expenseAmount;
    }
  }

  final totalBalance = totalIncome - totalExpense;

  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  final remainingDays = (lastDay - now.day) + 1;

  final safeToSpend = (user.monthlyIncome - totalExpense) / remainingDays;

  final data = DashboardData(
    userName: user.name,
    monthlyIncome: user.monthlyIncome,
    monthlySavingsGoal: user.monthlySavingsGoal,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    totalBalance: totalBalance,
    safeToSpend: safeToSpend,
    recentTransactions: transactions.take(5).cast<TransactionModel>().toList(),
  );
  
  // Get preferred currency
  final currency = ref.read(preferencesProvider).currency;

  // Calculate dynamic top categories based on expense transaction frequency
  final categoryCounts = <TransactionCategory, int>{};
  for (final tx in transactions) {
    if (tx.isEncrypted) continue;
    if (tx.type == TransactionType.expense) {
      categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
    }
  }

  final sortedCategories = categoryCounts.keys.toList()
    ..sort((a, b) => categoryCounts[b]!.compareTo(categoryCounts[a]!));

  final topCategory1 = sortedCategories.isNotEmpty ? sortedCategories[0] : TransactionCategory.food;
  final topCategory2 = sortedCategories.length > 1 ? sortedCategories[1] : TransactionCategory.shopping;

  String getCategoryLabel(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food: return '🍔 Food';
      case TransactionCategory.shopping: return '🛍️ Shop';
      case TransactionCategory.travel: return '🚗 Travel';
      case TransactionCategory.bills: return '🧾 Bills';
      case TransactionCategory.entertainment: return '🎬 Fun';
      case TransactionCategory.health: return '💊 Health';
      case TransactionCategory.education: return '📚 Edu';
      case TransactionCategory.salary: return '💼 Salary';
      case TransactionCategory.freelance: return '💻 Work';
      case TransactionCategory.investment: return '📈 Invest';
      case TransactionCategory.gift: return '🎁 Gift';
      case TransactionCategory.transfer: return '🔄 Trans';
      case TransactionCategory.other:
      default:
        return '📦 Other';
    }
  }
  
  // Update HomeWidget with the latest stats and dynamic category configurations
  await HomeWidgetService.updateWidgetData(
    data: data,
    currency: currency,
    topCat1Name: topCategory1.name,
    topCat1Label: getCategoryLabel(topCategory1),
    topCat2Name: topCategory2.name,
    topCat2Label: getCategoryLabel(topCategory2),
  );
  
  return data;
});
