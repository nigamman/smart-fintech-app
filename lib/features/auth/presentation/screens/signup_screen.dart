import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_controller.dart';
import '../widgets/premium_widgets.dart';
import '../../../../commons/widgets/fumet_snack_bar.dart';
import '../../../../core/utils/thousands_formatter.dart';

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
  final _confirmPasswordController = TextEditingController();
  final _incomeController = TextEditingController();
  final _savingGoalController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _incomeController.dispose();
    _savingGoalController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      FumetSnackBar.showError(context, 'Passwords do not match');
      return;
    }

    final String cleanIncome = _incomeController.text.replaceAll(',', '').trim();
    final String cleanSavings = _savingGoalController.text.replaceAll(',', '').trim();

    final income = double.tryParse(cleanIncome) ?? 0.0;
    final savings = double.tryParse(cleanSavings) ?? 0.0;
    if (savings >= income) {
      FumetSnackBar.showError(context, 'Savings goal must be less than monthly income');
      return;
    }

    await ref.read(authControllerProvider.notifier).signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      monthlyIncome: income,
      monthlySavingsGoal: savings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          FumetSnackBar.showError(context, error);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Logo (Animated breathing + entrance fader)
                  const FadeInSlideUp(
                    delayMs: 0,
                    child: FumetLogo(),
                  ),

                  const SizedBox(height: 32),

                  // Title (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 50,
                    child: Text(
                      'Create your vault',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Offline-first, encrypted from day one',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Full Name Field (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 150,
                    child: PremiumTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'Ram',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email Field (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 200,
                    child: PremiumTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'ram@fumet.app',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Field (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 250,
                    child: PremiumTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: '••••••••',
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
                          color: AppColors.secondaryText,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password Field (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 300,
                    child: PremiumTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hintText: '••••••••',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Monthly Income Field (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 350,
                    child: PremiumTextField(
                      controller: _incomeController,
                      label: 'Monthly Income',
                      hintText: '45,000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsFormatter()],
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your monthly income';
                        }
                        final cleanValue = value.replaceAll(',', '').trim();
                        if (double.tryParse(cleanValue) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Monthly Savings Goal Field (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 400,
                    child: PremiumTextField(
                      controller: _savingGoalController,
                      label: 'Monthly Savings Goal',
                      hintText: '8,000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsFormatter()],
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your savings goal';
                        }
                        final cleanValue = value.replaceAll(',', '').trim();
                        if (double.tryParse(cleanValue) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Create Account Button (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 450,
                    child: BouncingButton(
                      text: 'Create account',
                      isLoading: authState.isLoading,
                      onPressed: _signUp,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Disclaimer Text (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 480,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryText,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'By continuing you agree to Fumet\'s '),
                            TextSpan(
                              text: 'Terms',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 520,
                    child: Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.border,
                            thickness: 1.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.disabledText,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.border,
                            thickness: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Buttons (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 560,
                    child: BouncingButton(
                      text: '',
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).loginWithGoogle();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google_icon.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Google',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Toggle Navigation Link (Entrance fader)
                  FadeInSlideUp(
                    delayMs: 600,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.pop();
                          },
                          child: Text(
                            'Log in',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dynamic input formatter that blocks all alphabets/symbols, leaving only digits,
/// and adds comma groupings as thousands separators.