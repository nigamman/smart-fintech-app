import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:uuid/uuid.dart';
import '../../firebase_options.dart';
import '../../features/dashboard/domain/entities/dashboard_data.dart';

@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  if (uri != null && uri.scheme == 'fumet' && uri.host == 'add_expense') {
    final amountString = uri.queryParameters['amount'] ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    final category = uri.queryParameters['category'] ?? 'other';
    final note = uri.queryParameters['note'] ?? 'Quick Expense';

    if (amount > 0) {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final transactionId = const Uuid().v4();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .doc(transactionId)
              .set({
            'id': transactionId,
            'userId': user.uid,
            'amount': amount,
            'type': 'expense',
            'category': category,
            'note': note,
            'transactionDate': DateTime.now().toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          });

          // Update stats immediately after adding transaction
          await _updateWidgetStatsFromBackground(user.uid);
        }
      } catch (e) {
        debugPrint('Error handling interactive background action: $e');
      }
    }
  }
}

// Map dynamic categories to user-friendly UI labels
String _getCategoryLabel(String cat) {
  switch (cat) {
    case 'food':
      return '🍔 Food';
    case 'shopping':
      return '🛍️ Shop';
    case 'travel':
      return '🚗 Travel';
    case 'bills':
      return '🧾 Bills';
    case 'entertainment':
      return '🎬 Fun';
    case 'health':
      return '💊 Health';
    case 'education':
      return '📚 Edu';
    case 'salary':
      return '💼 Salary';
    case 'freelance':
      return '💻 Work';
    case 'investment':
      return '📈 Invest';
    case 'gift':
      return '🎁 Gift';
    case 'transfer':
      return '🔄 Trans';
    case 'other':
    default:
      return '📦 Other';
  }
}

Future<void> _updateWidgetStatsFromBackground(String userId) async {
  try {
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userSnap.exists) return;
    final userData = userSnap.data()!;
    final monthlyIncome = (userData['monthlyIncome'] as num).toDouble();
    final monthlySavingsGoal = (userData['monthlySavingsGoal'] as num?)?.toDouble() ?? 0.0;

    final transactionsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    double totalIncome = 0;
    double totalExpense = 0;
    double monthlyExpense = 0;
    double todayExpense = 0;
    final now = DateTime.now();
    final categoryCounts = <String, int>{};

    for (final doc in transactionsSnap.docs) {
      final data = doc.data();
      final type = data['type'] as String;
      final amount = (data['amount'] as num).toDouble();
      final category = data['category'] as String? ?? 'other';
      final isSplit = data['isSplit'] as bool? ?? false;
      final splitPercentage = (data['splitPercentage'] as num?)?.toDouble() ?? 50.0;

      if (type == 'income') {
        totalIncome += amount;
      } else {
        double expenseAmount = amount;
        if (isSplit) {
          expenseAmount -= (amount * (splitPercentage / 100));
        }
        totalExpense += expenseAmount;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

        // Parse date for current month comparison
        final dateStr = data['transactionDate'] as String?;
        if (dateStr != null) {
          final txDate = DateTime.tryParse(dateStr)?.toLocal();
          if (txDate != null && txDate.year == now.year && txDate.month == now.month) {
            monthlyExpense += expenseAmount;
            if (txDate.day == now.day) {
              todayExpense += expenseAmount;
            }
          }
        }
      }
    }

    // Sort categories dynamically to find the top 2
    final sortedCategories = categoryCounts.keys.toList()
      ..sort((a, b) => categoryCounts[b]!.compareTo(categoryCounts[a]!));

    final topCat1Name = sortedCategories.isNotEmpty ? sortedCategories[0] : 'food';
    final topCat2Name = sortedCategories.length > 1 ? sortedCategories[1] : 'shopping';

    final topCat1Label = _getCategoryLabel(topCat1Name);
    final topCat2Label = _getCategoryLabel(topCat2Name);

    final totalBalance = totalIncome - totalExpense;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day) + 1;
    final daysDivider = remainingDays < 1 ? 1 : remainingDays;

    final monthlyExpenseExcludingToday = (monthlyExpense - todayExpense).clamp(0.0, double.infinity);
    final dailyBudget = (monthlyIncome - monthlySavingsGoal - monthlyExpenseExcludingToday) / daysDivider;
    final safeToSpend = dailyBudget - todayExpense;

    // Read currency from Hive in background
    await Hive.initFlutter();
    final box = await Hive.openBox('preferences');
    final currency = box.get('currency', defaultValue: '₹') as String;

    final safeToSpendText = '$currency${safeToSpend.toStringAsFixed(0)}';
    final totalBalanceText = 'Total Cash: $currency${totalBalance.toStringAsFixed(0)}';
    final remainingDaysText = '$remainingDays days remaining';

    await HomeWidget.saveWidgetData<String>('safe_to_spend_text', safeToSpendText);
    await HomeWidget.saveWidgetData<String>('total_balance_text', totalBalanceText);
    await HomeWidget.saveWidgetData<String>('remaining_days_text', remainingDaysText);
    
    // Save dynamic categories
    await HomeWidget.saveWidgetData<String>('top_category_1_name', topCat1Name);
    await HomeWidget.saveWidgetData<String>('top_category_1_label', topCat1Label);
    await HomeWidget.saveWidgetData<String>('top_category_2_name', topCat2Name);
    await HomeWidget.saveWidgetData<String>('top_category_2_label', topCat2Label);

    await HomeWidget.updateWidget(
      name: 'SafeToSpendWidgetProvider',
      androidName: 'SafeToSpendWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'SafeToSpendSmallWidgetProvider',
      androidName: 'SafeToSpendSmallWidgetProvider',
    );
  } catch (e) {
    debugPrint('Error updating widget stats from background: $e');
  }
}

class HomeWidgetService {
  HomeWidgetService._();

  static Future<void> initialize() async {
    try {
      await HomeWidget.registerInteractivityCallback(interactiveCallback);
    } catch (e) {
      debugPrint('Failed to initialize HomeWidgetService: $e');
    }
  }

  static Future<void> updateWidgetData({
    required DashboardData data,
    required String currency,
    required String topCat1Name,
    required String topCat1Label,
    required String topCat2Name,
    required String topCat2Label,
  }) async {
    try {
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final remainingDays = (lastDay - now.day) + 1;

      final safeToSpendText = '$currency${data.safeToSpend.toStringAsFixed(0)}';
      final totalBalanceText = 'Total Cash: $currency${data.totalBalance.toStringAsFixed(0)}';
      final remainingDaysText = '$remainingDays days remaining';

      // Save to HomeWidget shared storage as strings
      await HomeWidget.saveWidgetData<String>('safe_to_spend_text', safeToSpendText);
      await HomeWidget.saveWidgetData<String>('total_balance_text', totalBalanceText);
      await HomeWidget.saveWidgetData<String>('remaining_days_text', remainingDaysText);

      // Save top categories
      await HomeWidget.saveWidgetData<String>('top_category_1_name', topCat1Name);
      await HomeWidget.saveWidgetData<String>('top_category_1_label', topCat1Label);
      await HomeWidget.saveWidgetData<String>('top_category_2_name', topCat2Name);
      await HomeWidget.saveWidgetData<String>('top_category_2_label', topCat2Label);

      // Trigger native widget refresh
      await HomeWidget.updateWidget(
        name: 'SafeToSpendWidgetProvider',
        androidName: 'SafeToSpendWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'SafeToSpendSmallWidgetProvider',
        androidName: 'SafeToSpendSmallWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating home widget data: $e');
    }
  }
}
