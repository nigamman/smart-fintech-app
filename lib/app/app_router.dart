import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/transaction/domain/entities/transaction.dart';
import '../features/transaction/presentation/screens/add_transaction_screen.dart';
import '../features/transaction/presentation/screens/transaction_list_screen.dart';
import '../features/budget/domain/entities/budget.dart';
import '../features/budget/presentation/screens/budget_screen.dart';
import '../features/budget/presentation/screens/add_budget_screen.dart';
import '../core/enums/transaction_type.dart';

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
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionListScreen(),
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
        builder: (context, state) => const BudgetScreen(),
      ),

      GoRoute(
        path: '/add-budget',
        builder: (context, state) {
          final budget = state.extra as Budget?;
          return AddBudgetScreen(budget: budget);
        },
      ),
    ],

    redirect: (context, state) async {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/login' ||
              location == '/signup' ||
              location == '/forgot-password';

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // User is logged in
      if (location == '/') {
        return '/dashboard';
      }

      if (isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
  );
});