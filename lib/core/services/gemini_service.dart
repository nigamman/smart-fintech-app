import 'dart:convert';
import 'dart:io';

class GeminiService {
  /// Evaluates and generates a proactive financial nudge based on local ledger state.
  /// Falls back to local heuristics if [apiKey] is empty or the API call fails.
  static Future<String> generateProactiveNudge({
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
    required String apiKey,
  }) async {
    final hasKey = apiKey.trim().isNotEmpty;
    
    // Construct the context prompt for Gemini
    final prompt = _buildNudgePrompt(
      safeToSpend: safeToSpend,
      totalBalance: totalBalance,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      upcomingSubscriptions: upcomingSubscriptions,
      categoryProgresses: categoryProgresses,
    );

    if (hasKey) {
      try {
        return await _callGeminiApi(prompt: prompt, apiKey: apiKey);
      } catch (_) {
        // Fallback to local heuristic on API failure
      }
    }

    return _generateLocalHeuristicNudge(
      safeToSpend: safeToSpend,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      upcomingSubscriptions: upcomingSubscriptions,
      categoryProgresses: categoryProgresses,
    );
  }

  /// Calculates affordability advice for a specific purchase query.
  /// Falls back to local heuristics if [apiKey] is empty or the API call fails.
  static Future<String> getAffordabilityAdvice({
    required String query,
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
    required String apiKey,
  }) async {
    final hasKey = apiKey.trim().isNotEmpty;
    
    final prompt = _buildAffordabilityPrompt(
      query: query,
      safeToSpend: safeToSpend,
      totalBalance: totalBalance,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      upcomingSubscriptions: upcomingSubscriptions,
      categoryProgresses: categoryProgresses,
    );

    if (hasKey) {
      try {
        return await _callGeminiApi(prompt: prompt, apiKey: apiKey);
      } catch (_) {
        // Fallback to local heuristic on API failure
      }
    }

    return _generateLocalHeuristicAffordability(
      query: query,
      safeToSpend: safeToSpend,
      totalBalance: totalBalance,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      categoryProgresses: categoryProgresses,
    );
  }

  static Future<String> _callGeminiApi({
    required String prompt,
    required String apiKey,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      
      final body = json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      });
      request.write(body);
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final jsonResponse = json.decode(responseBody);
        
        final candidates = jsonResponse['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return (parts[0]['text'] as String).trim();
          }
        }
      }
      throw Exception('Gemini API Error: Status Code ${response.statusCode}');
    } finally {
      client.close();
    }
  }

  static String _buildNudgePrompt({
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
  }) {
    return '''
You are an intelligent, friendly AI financial counselor. Give the user a proactive, warm, and actionable "nudge" or advice based on their current monthly financial metrics. Keep the response exactly 1 to 2 sentences. Do not use bullet points, list format, or markdown headers.

Current Context:
- Safe to Spend Today: ₹${safeToSpend.toStringAsFixed(0)}
- Current Cash Balance: ₹${totalBalance.toStringAsFixed(0)}
- Monthly Budget: ₹${totalSpent.toStringAsFixed(0)} spent of ₹${totalLimit.toStringAsFixed(0)} limit
- Upcoming renewals next week: ${upcomingSubscriptions.map((s) => '${s['name']} (₹${s['amount']})').join(', ')}
- Budget progress by category: ${categoryProgresses.map((c) => '${c['category']}: ₹${c['spent']}/₹${c['limit']}').join(', ')}

Provide a smart, conversational nudge. For example, highlight if they have renewals coming up and which budget categories are close to being exceeded, then suggest a smart spending correction.
''';
  }

  static String _buildAffordabilityPrompt({
    required String query,
    required double safeToSpend,
    required double totalBalance,
    required double totalLimit,
    required double totalSpent,
    required List<Map<String, dynamic>> upcomingSubscriptions,
    required List<Map<String, dynamic>> categoryProgresses,
  }) {
    return '''
You are an intelligent, friendly AI financial counselor. The user is asking whether they can afford a purchase. Analyze their current monthly financial metrics and reply with a calculated Yes/No/Yes-if advice. Keep the response concise (2 to 3 sentences max). Answer directly.

User Query: "$query"

Current Context:
- Safe to Spend Today: ₹${safeToSpend.toStringAsFixed(0)}
- Current Cash Balance: ₹${totalBalance.toStringAsFixed(0)}
- Monthly Budget: ₹${totalSpent.toStringAsFixed(0)} spent of ₹${totalLimit.toStringAsFixed(0)} limit
- Upcoming renewals next week: ${upcomingSubscriptions.map((s) => '${s['name']} (₹${s['amount']})').join(', ')}
- Budget progress by category: ${categoryProgresses.map((c) => '${c['category']}: ₹${c['spent']}/₹${c['limit']}').join(', ')}

Compute whether the cash balance is sufficient, and if the purchase exceeds their daily Safe-to-Spend or category limits. Offer a clear recommendation (Yes, No, or Yes-if under certain conditions).
''';
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
    // Parse cost from query (extract numbers, e.g. "Can I afford ₹3,000 dinner?")
    final regExp = RegExp(r'\d[\d,]*');
    final match = regExp.firstMatch(query.replaceAll(',', ''));
    if (match == null) {
      return "I couldn't quite catch the price in your question. Please specify an amount, like: 'Can I afford a ₹3,000 dinner?'";
    }

    final cost = double.tryParse(match.group(0) ?? '') ?? 0.0;
    if (cost <= 0) {
      return "Please enter a valid amount to evaluate.";
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
