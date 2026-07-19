class GeminiService {
  /// Evaluates and generates a proactive financial nudge based on local ledger state.
  static Future<String> generateProactiveNudge({
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
    String apiKey = '',
  }) async {
    return _generateLocalHeuristicNudge(
      safeToSpend: safeToSpend,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      upcomingSubscriptions: upcomingSubscriptions,
      categoryProgresses: categoryProgresses,
    );
  }

  /// Calculates affordability advice for a specific purchase query.
  static Future<String> getAffordabilityAdvice({
    required String query,
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
    String apiKey = '',
  }) async {
    return _generateLocalHeuristicAffordability(
      query: query,
      safeToSpend: safeToSpend,
      totalBalance: totalBalance,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      categoryProgresses: categoryProgresses,
    );
  }

  static String _generateLocalHeuristicNudge({
    required double safeToSpend,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
  }) {
    // Check if any category is close to limit (>= 80%)
    Map<String, dynamic>? warningCategory;
    for (final cat in categoryProgresses) {
      final limit = (cat['limit'] as num).toDouble();
      final spent = (cat['spent'] as num).toDouble();
      if (limit > 0 && spent / limit >= 0.8) {
        warningCategory = cat;
        break;
      }
    }

    final totalRenewals = upcomingSubscriptions.fold<double>(0.0, (sum, sub) => sum + sub['amount']);
    final subNames = upcomingSubscriptions.map((s) => s['name'] as String).toList();

    if (warningCategory != null) {
      final catName = warningCategory['category'];
      final limit = warningCategory['limit'];
      final pct = ((warningCategory['spent'] / limit) * 100).toStringAsFixed(0);
      
      if (upcomingSubscriptions.isNotEmpty) {
        return "Hey! You are $pct% close to your $catName budget limit, and have upcoming subscription renewals (${subNames.join(', ')}) totalling ₹${totalRenewals.toStringAsFixed(0)} next week. We suggest holding off on shopping to balance your ledger.";
      }
      return "Alert! You have used $pct% of your monthly $catName budget. With a daily Safe-To-Spend of ₹${safeToSpend.toStringAsFixed(0)}, we recommend slowing down on discretionary spending for a few days.";
    }

    if (upcomingSubscriptions.isNotEmpty) {
      return "Notice: You have subscription renewals next week (${subNames.join(', ')}) totalling ₹${totalRenewals.toStringAsFixed(0)}. Your daily Safe-To-Spend is ₹${safeToSpend.toStringAsFixed(0)}, so you are in good shape if you keep your daily spending below this limit.";
    }

    if (totalLimit > 0 && totalSpent / totalLimit >= 0.8) {
      return "Attention: You have consumed ${((totalSpent/totalLimit)*100).toStringAsFixed(0)}% of your total budget. We suggest limiting new purchases until your next billing cycle.";
    }

    return "Looking good! Your ledger is in great shape this week. Keep tracking and staying within your daily Safe-To-Spend of ₹${safeToSpend.toStringAsFixed(0)} to hit your savings goal.";
  }

  static String _generateLocalHeuristicAffordability({
    required String query,
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> categoryProgresses,
  }) {
    final lowerQuery = query.toLowerCase().trim();

    // 1. Parse amount from query
    final regExp = RegExp(r'\d[\d,]*');
    final match = regExp.firstMatch(query.replaceAll(',', ''));
    final cost = match != null ? (double.tryParse(match.group(0) ?? '') ?? 0.0) : 0.0;

    // 2. Detect Greetings
    final isGreeting = lowerQuery == 'hi' ||
        lowerQuery == 'hello' ||
        lowerQuery == 'hey' ||
        lowerQuery.startsWith('hi ') ||
        lowerQuery.startsWith('hello ') ||
        lowerQuery.startsWith('hey ');

    if (isGreeting) {
      return "Hello! I am your AI Financial Counsel. How can I help you with your budget today? Feel free to ask about your status or check if you can afford a specific purchase!";
    }

    // 3. Detect Income / Addition Intent
    final isIncomeIntent = lowerQuery.contains('income') ||
        lowerQuery.contains('earn') ||
        lowerQuery.contains('add') ||
        lowerQuery.contains('salary') ||
        lowerQuery.contains('receive') ||
        lowerQuery.contains('deposit') ||
        lowerQuery.contains('bonus') ||
        lowerQuery.contains('plus');

    if (isIncomeIntent && cost > 0) {
      final newBalance = totalBalance + cost;
      return "Yes! Adding ₹${cost.toStringAsFixed(0)} as income is a great decision. It will increase your total cash balance from ₹${totalBalance.toStringAsFixed(0)} to ₹${newBalance.toStringAsFixed(0)}, which automatically increases your daily Safe-To-Spend threshold and improves your Financial Health Score!";
    }

    // 4. Detect Budget Status query
    final isStatusIntent = lowerQuery.contains('how is') ||
        lowerQuery.contains('status') ||
        lowerQuery.contains('summary') ||
        lowerQuery.contains('report') ||
        lowerQuery.contains('budget progress');

    if (isStatusIntent) {
      final budgetText = totalLimit > 0
          ? "You have spent ₹${totalSpent.toStringAsFixed(0)} out of your ₹${totalLimit.toStringAsFixed(0)} limit."
          : "You haven't set up a monthly budget limits yet.";
      return "Here is your current status: Your daily Safe-to-Spend is ₹${safeToSpend.toStringAsFixed(0)}, and your current cash balance is ₹${totalBalance.toStringAsFixed(0)}. $budgetText Keep track of daily expenses to maintain positive savings velocity.";
    }

    // 5. Default to Affordability (Expense/Spending) Check
    if (cost <= 0) {
      return "I couldn't detect a specific amount in your request. Try asking something like: 'Can I afford a ₹3,000 dinner tonight?' or 'How is my budget looking?'";
    }

    if (cost > totalBalance) {
      return "No. This purchase of ₹${cost.toStringAsFixed(0)} exceeds your current total cash balance of ₹${totalBalance.toStringAsFixed(0)}. Making this purchase would put you in immediate deficit.";
    }

    if (cost <= safeToSpend) {
      return "Yes! A purchase of ₹${cost.toStringAsFixed(0)} is fully covered by your daily Safe-To-Spend of ₹${safeToSpend.toStringAsFixed(0)}. It fits perfectly within your budget today, so you are good to go!";
    }

    if (totalLimit > 0 && (totalSpent + cost) > totalLimit) {
      return "No. Your monthly budget limit is ₹${totalLimit.toStringAsFixed(0)}. Adding this ₹${cost.toStringAsFixed(0)} purchase will push your total expenses to ₹${(totalSpent + cost).toStringAsFixed(0)}, exceeding your set monthly budget.";
    }

    final dailyDeficit = cost - safeToSpend;
    return "Yes-if. While you have sufficient cash balance, this purchase of ₹${cost.toStringAsFixed(0)} exceeds your daily Safe-To-Spend of ₹${safeToSpend.toStringAsFixed(0)} by ₹${dailyDeficit.toStringAsFixed(0)}. You can afford it *if* you reduce your spending on other categories by ₹${(dailyDeficit / 3).toStringAsFixed(0)} per day over the next three days.";
  }
}
