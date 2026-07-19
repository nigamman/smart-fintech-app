import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'home_screen.dart';
import '../../../transaction/presentation/screens/activity_screen.dart';
import '../../../budget/presentation/screens/planning_screen.dart';
import '../../../analytics/presentation/screens/insights_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../../transaction/domain/entities/transaction.dart';

final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    ActivityScreen(),
    InsightsScreen(),
    PlanningScreen(),
  ];

  bool _isUnlockSheetOpen = false;

  void _showAutoUnlockSheet(BuildContext context) {
    if (_isUnlockSheetOpen) return;
    _isUnlockSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5B266).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Color(0xFFD5B266),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock Encrypted Ledger',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This account has Zero-Knowledge Sync enabled. Enter your sync passphrase to decrypt and recover your transaction history locally.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                obscureText: true,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'Sync Passphrase',
                  hintText: 'Enter your passphrase',
                  prefixIcon: const Icon(Icons.key_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final passphrase = controller.text.trim();
                  if (passphrase.isNotEmpty) {
                    ref.read(preferencesProvider.notifier).setPassphrase(passphrase);
                    Navigator.pop(context);
                    _isUnlockSheetOpen = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ledger decrypted successfully! Welcome back.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD5B266),
                  foregroundColor: isDark ? const Color(0xFF020617) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Unlock Ledger',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF020617)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _isUnlockSheetOpen = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Viewing app in locked sync mode. Cloud entries are hidden.'),
                    ),
                  );
                },
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    
    // Check if the app was initially launched from a widget click
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });

    // Listen to incoming clicks when app is already running
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  void _handleWidgetUri(Uri uri) {
    debugPrint('Widget click intercepted in Flutter: $uri');
    if (uri.scheme == 'fintrack') {
      if (uri.host == 'add-transaction') {
        final category = uri.queryParameters['category'];
        final type = uri.queryParameters['type'] ?? 'expense';
        
        // Push the Add Transaction screen
        String path = '/add-transaction?type=$type';
        if (category != null) {
          path += '&category=$category';
        }
        context.push(path);
      } else if (uri.host == 'dashboard') {
        // Switch main tab to Home
        ref.read(mainNavigationIndexProvider.notifier).state = 0;
      }
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  context,
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.expense,
                  title: 'Add Expense',
                  subtitle: 'Record an outgoing payment or purchase',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-transaction?type=expense');
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  color: AppColors.income,
                  title: 'Add Income',
                  subtitle: 'Log earnings, salary, or side income',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-transaction?type=income');
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.track_changes_rounded,
                  color: const Color(0xFFC8A05B),
                  title: 'Create Goal',
                  subtitle: 'Set and track targeted savings goals',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-savings-goal');
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.calendar_today_rounded,
                  color: Colors.blueAccent,
                  title: 'Add Bill / Sub',
                  subtitle: 'Log recurring bill cycles or subscriptions',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-subscription');
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.splitscreen_rounded,
                  color: Colors.deepPurpleAccent,
                  title: 'Split Ledger',
                  subtitle: 'Split bills and manage roommate balances',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/split-ledger');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: color.withOpacity(0.1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.secondaryText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Transaction>>>(transactionsStreamProvider, (previous, next) {
      final transactions = next.value ?? [];
      final preferences = ref.read(preferencesProvider);
      final hasEncrypted = transactions.any((tx) => tx.isEncrypted);
      final isLocked = hasEncrypted && (!preferences.isEncryptionEnabled || preferences.syncPassphrase == null);
 
      if (isLocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAutoUnlockSheet(context);
        });
      }
    });

    final selectedIndex = ref.watch(mainNavigationIndexProvider);
 
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Ledger'),
            
            // Middle Quick Action Button
            GestureDetector(
              onTap: () => _showQuickActions(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.background,
                  size: 26,
                ),
              ),
            ),

            _buildNavItem(2, Icons.donut_large_outlined, Icons.donut_large_rounded, 'Insights'),
            _buildNavItem(3, Icons.diamond_outlined, Icons.diamond_rounded, 'Vault'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final selectedIndex = ref.watch(mainNavigationIndexProvider);
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () {
        ref.read(mainNavigationIndexProvider.notifier).state = index;
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? AppColors.primary : AppColors.secondaryText.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.secondaryText.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
