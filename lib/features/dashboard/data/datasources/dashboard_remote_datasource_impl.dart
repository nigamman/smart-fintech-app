import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../domain/entities/dashboard_data.dart';
import 'dashboard_remote_datasource.dart';

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const DashboardRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<DashboardData> getDashboardData() async {
    final firebaseUser = auth.currentUser;

    if (firebaseUser == null) {
      throw Exception('User not logged in.');
    }

    final userSnapshot = await firestore
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid)
        .get();

    if (!userSnapshot.exists) {
      throw Exception('User profile not found.');
    }

    final userData = userSnapshot.data()!;

    final transactionSnapshot = await firestore
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid)
        .collection(FirestoreCollections.transactions)
        .orderBy('transactionDate', descending: true)
        .get();

    final transactions = transactionSnapshot.docs
        .map(
          (doc) => TransactionModel.fromJson(doc.data()),
    )
        .toList();

    double totalIncome = 0;
    double totalExpense = 0;
    double monthlyExpense = 0;
    final now = DateTime.now();

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        double expenseAmount = transaction.amount;
        if (transaction.isSplit) {
          final share = transaction.splitPercentage ?? 50.0;
          expenseAmount -= (transaction.amount * (share / 100));
        }
        totalExpense += expenseAmount;

        // Calculate current month's expenses only
        final txDate = transaction.transactionDate;
        if (txDate.year == now.year && txDate.month == now.month) {
          monthlyExpense += expenseAmount;
        }
      }
    }

    final totalBalance = totalIncome - totalExpense;

    final monthlyIncome =
    (userData['monthlyIncome'] as num).toDouble();

    final monthlySavingsGoal =
    (userData['monthlySavingsGoal'] as num).toDouble();

    final lastDay =
        DateTime(now.year, now.month + 1, 0).day;

    final remainingDays = (lastDay - now.day) + 1;
    final daysDivider = remainingDays < 1 ? 1 : remainingDays;

    final safeToSpend =
        (monthlyIncome - monthlySavingsGoal - monthlyExpense) / daysDivider;

    return DashboardData(
      userName: userData['name'],
      monthlyIncome: monthlyIncome,
      monthlySavingsGoal: monthlySavingsGoal,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalBalance: totalBalance,
      safeToSpend: safeToSpend,
      monthlyExpense: monthlyExpense,
      recentTransactions: transactions.take(5).toList(),
    );
  }
}