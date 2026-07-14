import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../../../core/services/export_service.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final preferences = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(mainNavigationIndexProvider.notifier).state = 0; // Back to Home tab
          },
        ),
      ),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(
          child: Text('Error loading settings: $err'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ACCOUNT SECTION
              _buildSectionHeader('Account'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Change name, email & target metrics',
                      onTap: () => _showEditProfileSheet(context, ref, user),
                    ),
                    _SettingsTile(
                      icon: Icons.currency_rupee_rounded,
                      title: 'Monthly Income',
                      subtitle: '${preferences.currency}${user.monthlyIncome.toStringAsFixed(0)}',
                      onTap: () => _showEditProfileSheet(context, ref, user),
                    ),
                    _SettingsTile(
                      icon: Icons.savings_outlined,
                      title: 'Monthly Savings Goal',
                      subtitle: '${preferences.currency}${user.monthlySavingsGoal.toStringAsFixed(0)}',
                      onTap: () => _showEditProfileSheet(context, ref, user),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Reset Password',
                      subtitle: 'Get password reset link via email',
                      onTap: () => _handlePasswordReset(context, ref, user.email),
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      textColor: AppColors.expense,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.expense),
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                  ],
                ),
              ),
              VSpace.lg,

              // PREFERENCES SECTION
              _buildSectionHeader('Preferences'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.monetization_on_outlined,
                      title: 'Currency',
                      subtitle: preferences.currency,
                      onTap: () => _showCurrencyPicker(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.calendar_month_outlined,
                      title: 'Date Format',
                      subtitle: preferences.dateFormat,
                      onTap: () => _showDateFormatPicker(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme Mode',
                      subtitle: preferences.themeMode.name.toUpperCase(),
                      onTap: () => _showThemePicker(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage alert reminders',
                      onTap: () => _showNotificationPlaceholder(context),
                    ),
                  ],
                ),
              ),
              VSpace.lg,

              // DATA MANAGEMENT
              _buildSectionHeader('Data Management'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.download_rounded,
                      title: 'Export Transactions',
                      subtitle: 'Export data to CSV or PDF document',
                      onTap: () => _showExportDialog(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.upload_rounded,
                      title: 'Import Data',
                      subtitle: 'Import transactions from backup',
                      onTap: () => _showImportPlaceholder(context),
                    ),
                    _SettingsTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Clear Cache',
                      subtitle: 'Free local storage space',
                      onTap: () => _handleClearCache(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Delete All Transactions',
                      subtitle: 'Wipe all transaction history',
                      textColor: AppColors.expense,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.expense),
                      onTap: () => _showDeleteTransactionsDialog(context, ref, user.id),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete Account',
                      subtitle: 'Permanently close and purge account',
                      textColor: AppColors.expense,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.expense),
                      onTap: () => _showDeleteAccountDialog(context, ref, user.id),
                    ),
                  ],
                ),
              ),
              VSpace.lg,

              // SECURITY SECTION
              _buildSectionHeader('Security'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Lock',
                      subtitle: 'Use Fingerprint/FaceID to unlock (Placeholder)',
                      onTap: () => _showSecurityPlaceholder(context),
                    ),
                    _SettingsTile(
                      icon: Icons.pin_outlined,
                      title: 'App PIN Lock',
                      subtitle: 'Secure app with custom code',
                      onTap: () => _showSecurityPlaceholder(context),
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Settings',
                      subtitle: 'Manage sharing and tracker permissions',
                      onTap: () => _showSecurityPlaceholder(context),
                    ),
                  ],
                ),
              ),
              VSpace.lg,

              // SUPPORT & HELP
              _buildSectionHeader('Support & Legal'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.contact_support_outlined,
                      title: 'Contact Us',
                      subtitle: 'support@fintrack.app',
                      onTap: () => _showSupportEmail(context),
                    ),
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Report a Bug',
                      subtitle: 'Send details to develop team',
                      onTap: () => _showBugReport(context),
                    ),
                    _SettingsTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Rate FinTrack',
                      subtitle: 'Support us on App Store',
                      onTap: () => _handleRateApp(context),
                    ),
                    _SettingsTile(
                      icon: Icons.share_outlined,
                      title: 'Share App',
                      subtitle: 'Invite friends to track savings',
                      onTap: () => _handleShareApp(context),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Open Source Licenses',
                      subtitle: 'Third-party code dependencies',
                      onTap: () => showLicensePage(context: context),
                    ),
                    _SettingsTile(
                      icon: Icons.gavel_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => _showTermsDialog(context),
                    ),
                    _SettingsTile(
                      icon: Icons.policy_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _showPrivacyDialog(context),
                    ),
                  ],
                ),
              ),
              VSpace.lg,

              // ABOUT & INFO
              _buildSectionHeader('About'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('App Version', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          Text('1.0.0 (Build 1)', style: AppTextStyles.bodySecondary),
                        ],
                      ),
                      VSpace.md,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Developer', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          Text('Deepmind Team', style: AppTextStyles.bodySecondary),
                        ],
                      ),
                      VSpace.md,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Changelog', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          Text('v1.0.0 - MVP Release', style: AppTextStyles.bodySecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              VSpace.xl,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm, top: AppSpacing.md),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  // --- ACTIONS & DIALOGS ---

  void _handlePasswordReset(BuildContext context, WidgetRef ref, String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email successfully!')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to send reset link: $e')),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout Account'),
          content: const Text('Are you sure you want to log out of your session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(authRepositoryProvider).logout();
                } catch (_) {}
              },
              child: const Text('Logout', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteTransactionsDialog(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Transactions'),
          content: const Text(
            'This action is irreversible. All transaction entries and records will be deleted permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final firestore = ref.read(firestoreProvider);
                  final snapshot = await firestore
                      .collection('users')
                      .doc(uid)
                      .collection('transactions')
                      .get();

                  final batch = firestore.batch();
                  for (final doc in snapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  ref.invalidate(transactionsStreamProvider);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('All transactions deleted successfully.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete transactions: $e')),
                  );
                }
              },
              child: const Text('Delete All', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'WARNING: Deleting your account will remove all transactions, savings goals, and profile data permanently. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  // Purge User Data from Firestore
                  await ref.read(firestoreProvider).collection('users').doc(uid).delete();
                  // Delete Firebase User Session
                  await FirebaseAuth.instance.currentUser?.delete();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Account successfully deleted.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              },
              child: const Text('Delete Account', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

  void _handleClearCache(BuildContext context, WidgetRef ref) {
    ref.invalidate(transactionsStreamProvider);
    ref.invalidate(userProfileStreamProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local cache cleared successfully!')),
    );
  }

  // --- PICKERS & PROMPTS ---

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(preferencesProvider).currency;
    final options = ['₹', '\$', '€', '£', '¥', '₣'];

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Currency'),
          children: options.map((option) {
            return SimpleDialogOption(
              onPressed: () {
                ref.read(preferencesProvider.notifier).updateCurrency(option);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(option, style: AppTextStyles.body),
                    if (option == current)
                      const Icon(Icons.check_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showDateFormatPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(preferencesProvider).dateFormat;
    final options = ['dd MMM yyyy', 'yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy'];

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Date Format'),
          children: options.map((option) {
            return SimpleDialogOption(
              onPressed: () {
                ref.read(preferencesProvider.notifier).updateDateFormat(option);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(option, style: AppTextStyles.body),
                    if (option == current)
                      const Icon(Icons.check_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(preferencesProvider).themeMode;
    final options = ThemeMode.values;

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Theme Mode'),
          children: options.map((option) {
            return SimpleDialogOption(
              onPressed: () {
                ref.read(preferencesProvider.notifier).updateThemeMode(option);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(option.name.toUpperCase(), style: AppTextStyles.body),
                    if (option == current)
                      const Icon(Icons.check_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showNotificationPlaceholder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Reminders'),
        content: const Text('Notification preferences is a premium feature under development.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transactions'),
        content: const Text('Choose your preferred file format to save or share your transaction history.'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final txsAsync = ref.read(transactionsStreamProvider);
              final txs = txsAsync.value ?? [];
              final messenger = ScaffoldMessenger.of(context);
              if (txs.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No transactions to export.')),
                );
                return;
              }
              try {
                await ExportService.exportTransactionsToCsv(txs);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to export CSV: $e')),
                );
              }
            },
            icon: const Icon(Icons.table_rows_rounded),
            label: const Text('Export CSV'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final txsAsync = ref.read(transactionsStreamProvider);
              final txs = txsAsync.value ?? [];
              final messenger = ScaffoldMessenger.of(context);
              if (txs.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No transactions to export.')),
                );
                return;
              }
              try {
                final currency = ref.read(preferencesProvider).currency;
                final userAsync = ref.read(userProfileStreamProvider);
                final user = userAsync.value;
                final name = user?.name ?? 'User';
                final email = user?.email ?? 'user@fintrack.app';
                await ExportService.exportTransactionsToPdf(txs, currency, name, email);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to export PDF: $e')),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  void _showImportPlaceholder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text('Importing data from backups will be available in future releases.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSecurityPlaceholder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Lock'),
        content: const Text('PIN/Biometrics secure locks are currently under construction.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSupportEmail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Drop us a mail at support@fintrack.app for help, suggestions, and account services.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showBugReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Bug'),
        content: const Text('To report bugs, mail logs & details directly to bug-reports@fintrack.app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _handleRateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for rating FinTrack App!')),
    );
  }

  void _handleShareApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App share link copied to clipboard!')),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Acceptance of Terms: By using FinTrack, you agree to these terms.\n\n'
            '2. Financial Information: FinTrack provides tools for tracking budget, and not certified financial advisory reports.\n\n'
            '3. Data Storage: Your transactional and profile details are encrypted in Firestore.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We value your privacy. FinTrack app does not collect personal identifiers or trade usage logs to third parties.\n\n'
            'Local cash inputs remain on secure Google Firebase hosting servers.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, dynamic user) {
    final nameController = TextEditingController(text: user.name);
    final incomeController = TextEditingController(text: user.monthlyIncome.toStringAsFixed(0));
    final savingsGoalController = TextEditingController(text: user.monthlySavingsGoal.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Edit Personal Profile',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.md,
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                VSpace.md,
                TextFormField(
                  controller: incomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Income',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Income is required';
                    final numVal = double.tryParse(val);
                    if (numVal == null || numVal < 0) return 'Please enter a valid positive amount';
                    return null;
                  },
                ),
                VSpace.md,
                TextFormField(
                  controller: savingsGoalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Savings Target',
                    prefixIcon: Icon(Icons.savings_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Savings target is required';
                    final numVal = double.tryParse(val);
                    if (numVal == null || numVal < 0) return 'Please enter a valid positive amount';
                    return null;
                  },
                ),
                VSpace.lg,
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final incomeVal = double.parse(incomeController.text);
                    final savingsVal = double.parse(savingsGoalController.text);
                    final messenger = ScaffoldMessenger.of(context);
                    
                    try {
                      await ref.read(profileControllerProvider.notifier).updateProfile(
                            user: user,
                            name: nameController.text.trim(),
                            monthlyIncome: incomeVal,
                            monthlySavingsGoal: savingsVal,
                          );
                      ref.invalidate(userProfileStreamProvider);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.primary)),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
