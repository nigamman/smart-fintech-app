import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/premium_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _logoPulseController;
  static const int _totalPages = 7;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _logoPulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefsBox = Hive.box('preferences');
    await prefsBox.put('has_seen_onboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Little app icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.primary, width: 1.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/icons/icon-master-1024.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fumet',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.disabledText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sliding pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage(
                    title: 'your money met,\n— on fumet.',
                    description:
                        'Welcome to Fumet, the zero-knowledge private ledger. Ownership of your data, budgets, and savings is absolute.',
                    illustration: _LogoWelcomeIllustration(pulseAnimation: _logoPulseController),
                  ),
                  _buildPage(
                    title: 'Zero-Knowledge Security',
                    description:
                        'Lock down your financials. Enable the Privacy Shield with a 6-digit Sync PIN to secure your cloud database with device-side encryption.',
                    illustration: _PrivacyShieldIllustration(pulseAnimation: _logoPulseController),
                  ),
                  _buildPage(
                    title: 'Home Screen Widgets',
                    description:
                        'Access budgets instantly. Track your Safe-to-Spend limit and log frequent transactions (like Coffee) directly from your Android Home Screen widgets.',
                    illustration: _HomeWidgetIllustration(pulseAnimation: _logoPulseController),
                  ),
                  _buildPage(
                    title: 'Safe to Spend Today',
                    description:
                        'No more mental math. Fumet tells you exactly how much is safe to spend today without breaking your budgets or savings goals.',
                    illustration: _SafeToSpendIllustration(pulseAnimation: _logoPulseController),
                  ),
                  _buildPage(
                    title: 'Friends Split Ledger',
                    description:
                        'Split bills and log expenses with friends. Check outstanding friends balances and settle up instantly with settled markers.',
                    illustration: _SplitLedgerIllustration(pulseAnimation: _logoPulseController),
                  ),
                  _buildPage(
                    title: 'Subscription Reminders',
                    description:
                        'Never get surprised by auto-renewals. Monitor recurring subscriptions and get alerts before bills deduct from your account.',
                    illustration: _SubscriptionsIllustration(pulseAnimation: _logoPulseController),
                  ),
                  _buildPage(
                    title: 'Premium PDF Statements',
                    description:
                        'Export clean financial logs. Generate and download beautifully formatted official PDF or CSV statements to share instantly.',
                    illustration: _StatementExportIllustration(pulseAnimation: _logoPulseController),
                  ),
                ],
              ),
            ),

            // Pagination Indicator and Bottom Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) => _buildIndicator(index)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _totalPages - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required Widget illustration,
  }) {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Center(child: illustration),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.secondaryText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isSelected ? 24 : 6,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// PREMIUM ILLUSTRATIONS

class _LogoWelcomeIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _LogoWelcomeIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: pulseAnimation, curve: Curves.easeInOutSine),
      ),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 40,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            'assets/icons/icon-master-1024.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _PrivacyShieldIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _PrivacyShieldIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: pulseAnimation, curve: Curves.easeInOutSine),
      ),
      child: Container(
        width: 200,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary, width: 1.0),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Zero-Knowledge Sync',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeWidgetIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _HomeWidgetIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fumet Widget',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(Icons.add, color: AppColors.background, size: 12),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '☕ Coffee',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '🍔 Food',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafeToSpendIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _SafeToSpendIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 6,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹1,240',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                'safe limit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _SplitLedgerIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _SplitLedgerIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.income.withOpacity(0.15),
                child: Text('R', style: GoogleFonts.fraunces(color: AppColors.income, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text('Ram', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('+₹450', style: GoogleFonts.plusJakartaSans(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.expense.withOpacity(0.15),
                child: Text('S', style: GoogleFonts.fraunces(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text('Shyam', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('-₹200', style: GoogleFonts.plusJakartaSans(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _SubscriptionsIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Netflix',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Renews in 3 days',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementExportIllustration extends StatelessWidget {
  final AnimationController pulseAnimation;
  const _StatementExportIllustration({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: pulseAnimation, curve: Curves.easeInOutSine),
      ),
      child: Container(
        width: 190,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.expense, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary, width: 0.8),
                  ),
                  child: Text(
                    'EXPORT',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 6, color: AppColors.border, width: 100),
                      const SizedBox(height: 6),
                      Container(height: 4, color: AppColors.border.withOpacity(0.5), width: 60),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}
