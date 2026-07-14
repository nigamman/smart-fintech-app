import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/main_navigation_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/transaction/domain/entities/transaction.dart';
import '../features/transaction/presentation/screens/add_transaction_screen.dart';
import '../features/transaction/presentation/screens/transaction_list_screen.dart';
import '../features/budget/domain/entities/budget.dart';
import '../features/budget/presentation/screens/budget_screen.dart';
import '../features/budget/presentation/screens/add_budget_screen.dart';
import '../core/enums/transaction_type.dart';
import '../features/savings_goal/domain/entities/savings_goal.dart';
import '../features/savings_goal/presentation/screens/savings_goal_list_screen.dart';
import '../features/savings_goal/presentation/screens/add_savings_goal_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/subscription/domain/entities/subscription.dart';
import '../features/subscription/presentation/screens/subscription_list_screen.dart';
import '../features/subscription/presentation/screens/add_subscription_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier();

  ref.listen(authStateProvider, (_, __) {
    refreshNotifier.refresh();
  });

  ref.onDispose(() {
    refreshNotifier.dispose();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/transactions',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/add-transaction',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          final initialTypeStr = state.uri.queryParameters['type'];
          final initialType = initialTypeStr == 'income'
              ? TransactionType.income
              : TransactionType.expense;
          return AddTransactionScreen(
            transaction: transaction,
            initialType: initialType,
          );
        },
      ),

      GoRoute(
        path: '/budget',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/add-budget',
        builder: (context, state) {
          final budget = state.extra as Budget?;
          return AddBudgetScreen(budget: budget);
        },
      ),

      GoRoute(
        path: '/savings-goals',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/add-savings-goal',
        builder: (context, state) {
          final goal = state.extra as SavingsGoal?;
          return AddSavingsGoalScreen(savingsGoal: goal);
        },
      ),

      GoRoute(
        path: '/analytics',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/calendar',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/add-subscription',
        builder: (context, state) {
          final sub = state.extra as Subscription?;
          return AddSubscriptionScreen(subscription: sub);
        },
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],

    redirect: (context, state) async {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/login' ||
              location == '/signup' ||
              location == '/forgot-password';

      // Check onboarding status
      final prefsBox = Hive.box('preferences');
      final hasSeenOnboarding = prefsBox.get('has_seen_onboarding', defaultValue: false);

      if (!hasSeenOnboarding) {
        if (location == '/onboarding') return null;
        return '/onboarding';
      }

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // User is logged in
      if (location == '/' || location == '/onboarding') {
        return '/dashboard';
      }

      if (isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
  );
});