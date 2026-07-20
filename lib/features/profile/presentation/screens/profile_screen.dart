import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../commons/widgets/app_text_field.dart';
import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../../../../core/utils/thousands_formatter.dart';
import '../../../../core/extensions/num_extensions.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _savingsGoalController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  void _submitProfile(dynamic user) async {
    if (!_formKey.currentState!.validate()) return;

    final incomeVal = double.tryParse(_incomeController.text.replaceAll(',', ''));
    if (incomeVal == null || incomeVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive monthly income.')),
      );
      return;
    }

    final savingsVal = double.tryParse(_savingsGoalController.text.replaceAll(',', ''));
    if (savingsVal == null || savingsVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive savings goal.')),
      );
      return;
    }

    if (savingsVal >= incomeVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal must be less than monthly income')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileControllerProvider.notifier).updateProfile(
            user: user,
            name: _nameController.text.trim(),
            monthlyIncome: incomeVal,
            monthlySavingsGoal: savingsVal,
          );
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  void _logout() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final controllerState = ref.watch(profileControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(
          child: Text('Error loading profile: $err'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found.'));
          }

          if (!_initialized) {
            _emailController.text = user.email;
            _nameController.text = user.name;
            _incomeController.text = user.monthlyIncome.toCommaFormat();
            _savingsGoalController.text = user.monthlySavingsGoal.toCommaFormat();
            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Email (Read-only)
                Text(
                  'EMAIL ADDRESS',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.md,
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  enabled: false,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                VSpace.xl,

                // Full Name
                Text(
                  'FULL NAME',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.md,
                AppTextField(
                  controller: _nameController,
                  label: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                VSpace.xl,

                // Monthly Income
                Text(
                  'MONTHLY INCOME',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.md,
                AppTextField(
                  controller: _incomeController,
                  label: 'e.g. 50000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Monthly income is required';
                    final cleanVal = val.replaceAll(',', '');
                    if (double.tryParse(cleanVal) == null || double.parse(cleanVal) < 0) {
                      return 'Enter a valid non-negative amount';
                    }
                    return null;
                  },
                ),
                VSpace.xl,

                // Monthly Savings Goal
                Text(
                  'MONTHLY SAVINGS TARGET',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.md,
                AppTextField(
                  controller: _savingsGoalController,
                  label: 'e.g. 10000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  prefixIcon: const Icon(Icons.savings_outlined),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Monthly target is required';
                    final cleanVal = val.replaceAll(',', '');
                    if (double.tryParse(cleanVal) == null || double.parse(cleanVal) < 0) {
                      return 'Enter a valid non-negative amount';
                    }
                    return null;
                  },
                ),
                VSpace.xl,

                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: isLoading ? null : () => _submitProfile(user),
                  isLoading: isLoading,
                ),
                VSpace.lg,

                OutlinedButton.icon(
                  onPressed: isLoading ? null : _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
                  label: const Text('Logout Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
