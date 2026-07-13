import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
//import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // GoRoute(
      //   path: '/dashboard',
      //   builder: (context, state) => const DashboardScreen(),
      // ),
    ],

    redirect: (context, state) async {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      final isLoggingIn = state.matchedLocation == '/login';

      if (user == null && !isLoggingIn) {
        return '/login';
      }

      if (user != null && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
  );
});