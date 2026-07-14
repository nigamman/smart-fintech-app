import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../commons/widgets/app_text_field.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _incomeController = TextEditingController();
  final _savingGoalController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _incomeController.dispose();
    _savingGoalController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      monthlyIncome: double.parse(_incomeController.text.trim()),
      monthlySavingsGoal:
      double.parse(_savingGoalController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: AppTextStyles.display,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Start your financial journey today.',
                  style: AppTextStyles.bodySecondary,
                ),

                const SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),

                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your email'
                      : null,
                ),

                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _incomeController,
                  label: 'Monthly Income',
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your monthly income'
                      : null,
                ),

                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _savingGoalController,
                  label: 'Monthly Saving Goal',
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your saving goal'
                      : null,
                ),

                const SizedBox(height: AppSpacing.xl),

                PrimaryButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _signUp,
                ),

                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: AppTextStyles.bodySecondary,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}