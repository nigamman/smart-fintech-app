import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../../../core/services/export_service.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _activeTabIndex = 0;

  Widget _buildCategorySelector(int activeIndex, Function(int) onTap) {
    final categories = [
      {'icon': Icons.tune_rounded, 'label': 'General'},
      {'icon': Icons.widgets_outlined, 'label': 'Widgets'},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Info'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = activeIndex == index;
          final cat = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? AppColors.background : AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['label'] as String,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected ? AppColors.background : AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, dynamic user, dynamic preferences) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.disabledText,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit Icon Button
              InkWell(
                onTap: () => context.push('/edit-profile'),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: AppColors.border.withOpacity(0.5),
          ),
          const SizedBox(height: 14),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'MONTHLY INCOME',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.disabledText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${preferences.currency}${user.monthlyIncome.toStringAsFixed(0)}',
                      style: AppTextStyles.mono.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.border.withOpacity(0.5),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SAVINGS TARGET',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.disabledText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${preferences.currency}${user.monthlySavingsGoal.toStringAsFixed(0)}',
                      style: AppTextStyles.mono.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final preferences = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingIndicator(),
          error: (err, stack) => Center(
            child: Text('Error loading settings: $err', style: AppTextStyles.body),
          ),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('User profile not found.', style: TextStyle(color: Colors.white)));
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Custom Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 1. Profile Dashboard
                _buildProfileCard(context, ref, user, preferences),
                const SizedBox(height: 12),

                // 2. Category selection chips
                _buildCategorySelector(_activeTabIndex, (index) {
                  setState(() {
                    _activeTabIndex = index;
                  });
                }),
                const SizedBox(height: 12),

                // 3. Dynamic Setting Groups based on Selected Tab
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_activeTabIndex),
                    child: _buildSelectedSettingsContent(user, preferences),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedSettingsContent(dynamic user, dynamic preferences) {
    switch (_activeTabIndex) {
      case 0:
        final hasEncrypted = ref.watch(transactionsStreamProvider).value?.any((tx) => tx.isEncrypted) ?? false;
        final hasPassphrase = preferences.isEncryptionEnabled && preferences.syncPassphrase != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zero-Knowledge Sync section
            _buildSectionHeader('Zero-Knowledge Sync'),
            _buildSettingsCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.security_rounded,
                    title: 'Privacy Shield (Local Sync)',
                    subtitle: hasPassphrase
                        ? 'Active (Zero-Knowledge Protected)'
                        : 'Secure cloud backups with device-side encryption',
                    textColor: hasPassphrase ? const Color(0xFFC8A05B) : null,
                    trailing: Switch(
                      value: hasPassphrase,
                      activeColor: const Color(0xFFC8A05B),
                      onChanged: (val) {
                        if (val) {
                          if (preferences.isEncryptionEnabled || hasEncrypted) {
                            _showPinUnlockSheet(context);
                          } else {
                            _showPinSetupSheet(context, user.id);
                          }
                        } else {
                          _confirmDisableEncryption(context, user.id);
                        }
                      },
                    ),
                    onTap: () {
                      if (hasPassphrase) {
                        _confirmDisableEncryption(context, user.id);
                      } else {
                        if (preferences.isEncryptionEnabled || hasEncrypted) {
                          _showPinUnlockSheet(context);
                        } else {
                          _showPinSetupSheet(context, user.id);
                        }
                      }
                    },
                  ),
                  if (hasPassphrase)
                    _SettingsTile(
                      icon: Icons.key_rounded,
                      title: 'Change Sync PIN',
                      subtitle: 'Update your 6-digit passcode',
                      onTap: () => _showPinChangeSheet(context, user.id),
                    ),
                ],
              ),
            ),
            VSpace.lg,

            // Data Management section
            _buildSectionHeader('Data Management'),
            _buildSettingsCard(
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

            // Account Security section
            _buildSectionHeader('Account Security'),
            _buildSettingsCard(
              child: Column(
                children: [
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
          ],
        );
      case 1:
        return const _WidgetShowcaseCard();
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Support & Legal'),
            _buildSettingsCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Us',
                    subtitle: 'nigamman20@gmail.com',
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
                    title: 'Rate Fumet',
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
            _buildSectionHeader('About'),
            _buildSettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('App Version', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                        Text('2.1.2 ', style: AppTextStyles.bodySecondary),
                      ],
                    ),
                    VSpace.md,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Developer', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                        Text('nigamman', style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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

  void _showPinUnlockSheet(BuildContext context) {
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
        return const PinUnlockSheet();
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

  void _showPinChangeSheet(BuildContext context, String userId) {
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
        return PinUnlockSheet(isChange: true, userId: userId);
      },
    );
  }

  void _showSetupPassphraseDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Setup Privacy Shield'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a strong passphrase. This passphrase is used to encrypt your ledger before it leaves your device.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'WARNING: If you lose this passphrase, your remote backups cannot be decrypted. We cannot recover it for you.',
                  style: TextStyle(color: AppColors.expense, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'PIN must be exactly 6 digits';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sync PIN',
                    border: OutlineInputBorder(),
                    helperText: 'Exactly 6 digits',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value != controller.text) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final passphrase = controller.text.trim();
                  Navigator.pop(context);
                  
                  // Show loading dialog
                  showDialog(
                    context: this.context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Encrypting and syncing your ledger...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  try {
                    await ref.read(preferencesProvider.notifier).enableEncryption(passphrase, userId);
                    Navigator.pop(this.context); // close loading
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Privacy Shield enabled successfully! All backups are encrypted.')),
                    );
                  } catch (e) {
                    Navigator.pop(this.context); // close loading
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Failed to enable encryption: $e')),
                    );
                  }
                }
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePassphraseDialog(BuildContext context, String userId) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final preferences = ref.read(preferencesProvider);
    final correctCurrentPassphrase = preferences.syncPassphrase;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Change Sync Passphrase'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To update your sync passphrase, verify your current one first and then enter the new passphrase twice.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value != correctCurrentPassphrase) {
                        return 'Incorrect current PIN';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Current PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'New PIN must be exactly 6 digits';
                      }
                      if (value == currentController.text) {
                        return 'New PIN must be different';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'New PIN',
                      border: OutlineInputBorder(),
                      helperText: 'Exactly 6 digits',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value != newController.text) {
                        return 'PINs do not match';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Confirm New PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newPassphrase = newController.text.trim();
                  Navigator.pop(context);
                  
                  // Show loading
                  showDialog(
                    context: this.context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Updating encryption and backups...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  try {
                    await ref.read(preferencesProvider.notifier).enableEncryption(newPassphrase, userId);
                    Navigator.pop(this.context); // close loading
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Passphrase updated and remote backups re-encrypted successfully!')),
                    );
                  } catch (e) {
                    Navigator.pop(this.context); // close loading
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Failed to update passphrase: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }



  void _confirmDisableEncryption(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disable Privacy Shield?'),
          content: const Text(
            'Are you sure you want to disable Zero-Knowledge sync? Your remote backups will be decrypted and stored in plaintext in the cloud. This makes them readable by servers and third-party APIs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Show loading
                showDialog(
                  context: this.context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Decrypting and syncing backups...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  await ref.read(preferencesProvider.notifier).disableEncryption(userId);
                  Navigator.pop(this.context); // close loading
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Privacy Shield disabled. Cloud backups are now in plaintext.')),
                  );
                } catch (e) {
                  Navigator.pop(this.context); // close loading
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to disable encryption: $e')),
                  );
                }
              },
              child: const Text('Disable', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

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
                  await ref.read(authControllerProvider.notifier).logout();
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
                  final firestore = ref.read(firestoreProvider);
                  
                  // 1. Keep copy of user data in memory in case Auth deletion fails
                  final userSnap = await firestore.collection('users').doc(uid).get();
                  final userMap = userSnap.data();

                  // 2. Delete the Firestore user document
                  await firestore.collection('users').doc(uid).delete();

                  try {
                    // 3. Clear user preferences locally first
                    ref.read(preferencesProvider.notifier).clearUserPreferences();
                    
                    // 4. Delete Auth user session
                    await FirebaseAuth.instance.currentUser?.delete();
                    
                    // 5. Log out cleanly to reset UI and stream providers
                    await ref.read(authRepositoryProvider).logout();

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Account successfully deleted.')),
                    );
                  } catch (authError) {
                    // 6. Restore user document in Firestore if Auth deletion failed
                    if (userMap != null) {
                      await firestore.collection('users').doc(uid).set(userMap);
                    }
                    
                    // If it requires recent login, show specific instructions
                    if (authError is FirebaseAuthException && authError.code == 'requires-recent-login') {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('For security, please log out and log back in, then try deleting again.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error deleting account authentication: $authError')),
                      );
                    }
                  }
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
                final email = user?.email ?? 'user@fumet.app';
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
        content: const Text('Drop us a mail at support@fumet.app for help, suggestions, and account services.'),
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
        content: const Text('To report bugs, mail logs & details directly to bug-nigamman20@gmail.com.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _handleRateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for rating Fumet App!')),
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
            '1. Acceptance of Terms: By using Fumet, you agree to these terms.\n\n'
            '2. Financial Information: Fumet provides tools for tracking budget, and not certified financial advisory reports.\n\n'
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
            'At Fumet, we build private, zero-knowledge financial software. Your data ownership is absolute.\n\n'
            '1. DATA OWNERSHIP & ZERO-KNOWLEDGE SYNC\n'
            'When the Privacy Shield is enabled, your ledger entries are encrypted locally on your device with your 6-digit Sync PIN using AES-256 before synchronization. We do not have access to your encryption keys, and your cloud database backups are stored as ciphertext. We cannot read or access your financial logs.\n\n'
            '2. AUTHENTICATION & PROFILE DATA\n'
            'We store your name, email, and configured savings targets to manage authentication and user profiles. We do not collect other personal identifiers.\n\n'
            '3. NO THIRD-PARTY SHARING\n'
            'Fumet is ad-free and tracking-free. We do not trade, sell, or monitor your financial history or app usage logs.\n\n'
            'For support, contact nigamman20@gmail.com.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
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
      leading: Icon(icon, color: textColor ?? AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.white,
          fontSize: 13.5,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(color: AppColors.disabledText, fontSize: 11),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.disabledText),
      onTap: onTap,
    );
  }
}

class _WidgetShowcaseCard extends StatefulWidget {
  const _WidgetShowcaseCard();

  @override
  State<_WidgetShowcaseCard> createState() => _WidgetShowcaseCardState();
}

class _WidgetShowcaseCardState extends State<_WidgetShowcaseCard> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _glowController;

  static const _channel = MethodChannel('com.nigamman.fumet/widgets');

  Future<void> _requestPinWidget(String type) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
          'requestPinWidget', {'type': type});
      if (success != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not request widget pin automatically. Please add it manually.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to pin widget: '${e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )
      ..repeat(reverse: true);

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetPinned') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Widget successfully added to Home Screen! 🎉'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    // Auto-scroll logic to showcase both widgets
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % 2;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      _currentPage = nextPage;
      Future.delayed(const Duration(seconds: 4), _autoScroll);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Widget _buildPreviewButton(String icon, String label) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF24262E),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(
                color: icon == '☕' ? const Color(0xFF8A8EC4) : AppColors
                    .primary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFD5B266),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Color(0xFF18191D),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetPreview({required bool small}) {
    final title = small ? 'SAFE TODAY' : 'SAFE TO SPEND TODAY';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111216),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18191D),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: small
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8A8D9F),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '₹1,596',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Total Cash: ₹48,200',
                  style: TextStyle(
                    color: Color(0xFF7F8295),
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '16 days remaining',
                  style: TextStyle(
                    color: Color(0xFF7F8295),
                    fontSize: 9,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      color: Color(0xFF18191D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF8A8D9F),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '₹1,596',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Total Cash: ₹48,200',
                      style: TextStyle(
                        color: Color(0xFF7F8295),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      color: Color(0xFF18191D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildPreviewButton('◆', 'Food'),
                const SizedBox(width: 4),
                _buildPreviewButton('◇', 'Travel'),
                const SizedBox(width: 4),
                _buildPreviewButton('☕', 'Coffee'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.widgets_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GLANCE TRACKING',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      'Home Screen Widgets',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 190,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildWidgetPreview(small: true),
                _buildWidgetPreview(small: false),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Pin widget button
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final widgetType = _currentPage == 0 ? 'small' : 'medium';
                  _requestPinWidget(widgetType);
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppColors.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_to_home_screen_rounded,
                          color: AppColors.background, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _currentPage == 0
                            ? 'Add Small to Home'
                            : 'Add Medium to Home',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}