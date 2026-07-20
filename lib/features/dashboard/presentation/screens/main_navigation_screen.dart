import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
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
  bool _hasPromptedPinSetup = false;

  void _showAutoUnlockSheet(BuildContext context) {
    if (_isUnlockSheetOpen) return;
    _isUnlockSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) {
        return const PinUnlockSheet();
      },
    ).then((_) {
      _isUnlockSheetOpen = false;
    });
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

    // Prompt new users to setup Privacy Shield PIN if not enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptPinSetup();
    });
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  void _handleWidgetUri(Uri uri) {
    debugPrint('Widget click intercepted in Flutter: $uri');
    if (uri.scheme == 'fumet') {
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

  void _checkAndPromptPinSetup() {
    if (_hasPromptedPinSetup || _isUnlockSheetOpen) return;
    _hasPromptedPinSetup = true;

    final preferences = ref.read(preferencesProvider);
    if (!preferences.isEncryptionEnabled) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _showPinSetupOnboardingPrompt(context, currentUser.uid);
      }
    }
  }

  void _showPinSetupOnboardingPrompt(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secure Your Data',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable Privacy Shield by setting a 6-digit local PIN. This encrypts your ledger on-device before syncing to the cloud.',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Zero-Knowledge protection ensures that only you can decrypt your cashflow data.',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFC8A05B),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Skip for now',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.disabledText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPinSetupSheet(context, userId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                'Set up PIN',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPinSetupSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) {
        return PinUnlockSheet(isSetup: true, userId: userId);
      },
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
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
                    subtitle: 'Split bills and manage friends balances',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/split-ledger');
                    },
                  ),
                ],
              ),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
 
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 64 + bottomPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
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

class PinUnlockSheet extends ConsumerStatefulWidget {
  final bool isSetup;
  final bool isChange;
  final String? userId;

  const PinUnlockSheet({
    super.key,
    this.isSetup = false,
    this.isChange = false,
    this.userId,
  });

  @override
  ConsumerState<PinUnlockSheet> createState() => _PinUnlockSheetState();
}

class _PinUnlockSheetState extends ConsumerState<PinUnlockSheet> {
  String _enteredPin = '';
  String? _firstPin;
  String? _oldPinInput;

  void _handleKeyPress(String value) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += value;
    });

    if (_enteredPin.length == 6) {
      _submitPin();
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final preferences = ref.read(preferencesProvider);

    if (widget.isSetup) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        if (_enteredPin == _firstPin) {
          await ref.read(preferencesProvider.notifier).enableEncryption(_enteredPin, widget.userId ?? '');
          if (mounted) {
            Navigator.pop(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Privacy Shield enabled successfully!')),
            );
          }
        } else {
          setState(() {
            _firstPin = null;
            _enteredPin = '';
          });
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('PINs did not match. Please try again.')),
          );
        }
      }
    } else if (widget.isChange) {
      if (_oldPinInput == null) {
        if (_enteredPin == preferences.syncPassphrase) {
          setState(() {
            _oldPinInput = _enteredPin;
            _enteredPin = '';
          });
        } else {
          setState(() {
            _enteredPin = '';
          });
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Incorrect current PIN. Please try again.')),
          );
        }
      } else if (_firstPin == null) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        if (_enteredPin == _firstPin) {
          await ref.read(preferencesProvider.notifier).enableEncryption(_enteredPin, widget.userId ?? '');
          if (mounted) {
            Navigator.pop(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('PIN updated successfully!')),
            );
          }
        } else {
          setState(() {
            _firstPin = null;
            _enteredPin = '';
          });
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('PINs did not match. Please start again.')),
          );
        }
      }
    } else {
      if (_enteredPin == preferences.syncPassphrase) {
        ref.read(preferencesProvider.notifier).setPassphrase(_enteredPin);
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Ledger decrypted successfully! Welcome back.'),
          ),
        );
      } else {
        setState(() {
          _enteredPin = '';
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Incorrect PIN. Please try again.')),
        );
      }
    }
  }

  void _skipUnlock() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing app in locked sync mode. Cloud entries are hidden.'),
      ),
    );
  }

  void _showForgotPassphraseExplanation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFBC5B3E), size: 24),
              const SizedBox(width: 12),
              Text(
                'Forgotten PIN',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: const Text(
            'Fumet features zero-knowledge local encryption. This means your sync PIN is saved only on your device and can never be recovered by us.\n\n'
            'If you cannot remember it, you must log out to clear the local session and start fresh with a new sync key.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                await ref.read(authControllerProvider.notifier).logout();
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFBC5B3E)),
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKey(String label) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleKeyPress(label),
        child: Container(
          height: 70,
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Enter your PIN';
    String subtitle = 'Your data is encrypted on this device. Fumet cannot recover it if you forget your PIN.';
    IconData headerIcon = Icons.lock_outline_rounded;

    if (widget.isSetup) {
      headerIcon = Icons.security_rounded;
      if (_firstPin == null) {
        title = 'Create your PIN';
        subtitle = 'Choose a 6-digit passcode to secure your cloud backup.';
      } else {
        title = 'Confirm your PIN';
        subtitle = 'Re-enter your 6-digit passcode to verify.';
      }
    } else if (widget.isChange) {
      headerIcon = Icons.vpn_key_rounded;
      if (_oldPinInput == null) {
        title = 'Verify Current PIN';
        subtitle = 'Enter your current 6-digit passcode.';
      } else if (_firstPin == null) {
        title = 'Create New PIN';
        subtitle = 'Choose a new 6-digit passcode.';
      } else {
        title = 'Confirm New PIN';
        subtitle = 'Re-enter the new 6-digit passcode to verify.';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              
              // Padlock Monogram Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.0),
                ),
                alignment: Alignment.center,
                child: Icon(
                  headerIcon,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Dot Indicators (6 dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(filled ? 1.0 : 0.4),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Custom Keypad Grid
              Column(
                children: [
                  Row(
                    children: [
                      _buildKey('1'),
                      _buildKey('2'),
                      _buildKey('3'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildKey('4'),
                      _buildKey('5'),
                      _buildKey('6'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildKey('7'),
                      _buildKey('8'),
                      _buildKey('9'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Bottom-left Lock / Skip Key
                      Expanded(
                        child: InkWell(
                          onTap: (widget.isSetup || widget.isChange) ? null : _skipUnlock,
                          child: Container(
                            height: 70,
                            alignment: Alignment.center,
                            child: (widget.isSetup || widget.isChange)
                                ? const SizedBox.shrink()
                                : Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                      _buildKey('0'),
                      // Bottom-right Backspace Key
                      Expanded(
                        child: InkWell(
                          onTap: _handleBackspace,
                          child: Container(
                            height: 70,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.backspace_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Bottom links
              if (widget.isSetup || widget.isChange)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: _showForgotPassphraseExplanation,
                  child: Text(
                    'Forgot your PIN?',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _skipUnlock,
                  child: Text(
                    'Skip for now',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.disabledText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
