import 'package:flutter_test/flutter_test.dart';
import 'package:fintech_app/core/services/gemini_service.dart';

void main() {
  group('GeminiService Local Heuristics Fallback Tests', () {
    test('generateProactiveNudge returns warning if category is close to limit', () async {
      final nudge = await GeminiService.generateProactiveNudge(
        safeToSpend: 1000.0,
        totalBalance: 5000.0,
        totalLimit: 10000.0,
        totalSpent: 4000.0,
        upcomingSubscriptions: [],
        categoryProgresses: [
          {'category': 'Food', 'spent': 4500.0, 'limit': 5000.0}, // 90% spent
          {'category': 'Shopping', 'spent': 200.0, 'limit': 3000.0},
        ],
        apiKey: '',
      );

      expect(nudge, contains('Food'));
      expect(nudge, contains('used 90%'));
      expect(nudge, contains('recommend slowing down'));
    });

    test('generateProactiveNudge returns renewal warning if subscriptions are due next week', () async {
      final nudge = await GeminiService.generateProactiveNudge(
        safeToSpend: 1500.0,
        totalBalance: 8000.0,
        totalLimit: 5000.0,
        totalSpent: 1000.0,
        upcomingSubscriptions: [
          {'name': 'Netflix', 'amount': 199.0},
          {'name': 'Spotify', 'amount': 119.0},
        ],
        categoryProgresses: [
          {'category': 'Food', 'spent': 1000.0, 'limit': 5000.0},
        ],
        apiKey: '',
      );

      expect(nudge, contains('Netflix'));
      expect(nudge, contains('Spotify'));
      expect(nudge, contains('₹318'));
    });

    test('getAffordabilityAdvice returns Yes if cost is below safeToSpend', () async {
      final advice = await GeminiService.getAffordabilityAdvice(
        query: 'Can I afford ₹500 lunch?',
        safeToSpend: 1000.0,
        totalBalance: 5000.0,
        totalLimit: 10000.0,
        totalSpent: 2000.0,
        upcomingSubscriptions: [],
        categoryProgresses: [],
        apiKey: '',
      );

      expect(advice, startsWith('Yes!'));
      expect(advice, contains('fully covered by your daily Safe-To-Spend'));
    });

    test('getAffordabilityAdvice returns No if cost exceeds total balance', () async {
      final advice = await GeminiService.getAffordabilityAdvice(
        query: 'Can I afford a ₹15,000 laptop?',
        safeToSpend: 1000.0,
        totalBalance: 5000.0,
        totalLimit: 20000.0,
        totalSpent: 2000.0,
        upcomingSubscriptions: [],
        categoryProgresses: [],
        apiKey: '',
      );

      expect(advice, startsWith('No.'));
      expect(advice, contains('exceeds your current total cash balance'));
    });

    test('getAffordabilityAdvice returns Yes-if if cost is between safeToSpend and totalBalance', () async {
      final advice = await GeminiService.getAffordabilityAdvice(
        query: 'Can I afford a ₹2,000 jacket?',
        safeToSpend: 800.0,
        totalBalance: 5000.0,
        totalLimit: 10000.0,
        totalSpent: 2000.0,
        upcomingSubscriptions: [],
        categoryProgresses: [],
        apiKey: '',
      );

      expect(advice, startsWith('Yes-if.'));
      expect(advice, contains('exceeds your daily Safe-To-Spend'));
      expect(advice, contains('by ₹1200'));
    });
  });
}
