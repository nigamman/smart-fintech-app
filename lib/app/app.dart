import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/presentation/providers/settings_providers.dart';
import 'app_router.dart';

class FumetApp extends ConsumerWidget {
  const FumetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(preferencesProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fumet',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}