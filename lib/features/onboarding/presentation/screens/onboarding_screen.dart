import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _floatController;
  static const int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FinTrack',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
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
                    title: 'Can I Spend Today?',
                    description:
                        'No more mental math. We tell you exactly how much money is safe to spend today without worrying about bills or savings goals.',
                    illustration: _SafeToSpendIllustration(floatAnimation: _floatController),
                  ),
                  _buildPage(
                    title: 'Unified Planning',
                    description:
                        'Consolidate monthly budgets and track target savings goals directly within a single unified control center.',
                    illustration: const _PlanningIllustration(),
                  ),
                  _buildPage(
                    title: 'Bill & Subscription Reminders',
                    description:
                        'Never get surprised by auto-renewals. Track recurring subscriptions like Netflix or utility bills, and get notified before they hit.',
                    illustration: const _SubscriptionIllustration(),
                  ),
                  _buildPage(
                    title: 'Predictive Velocity Analytics',
                    description:
                        'Get ahead with financial predictions. Track daily spend speed and know exactly how many days your budget will last.',
                    illustration: const _PredictionsIllustration(),
                  ),
                  _buildPage(
                    title: 'Professional Statements',
                    description:
                        'Generate and export official PDF or CSV statements formatted with personalized metadata details to share instantly.',
                    illustration: _ExportIllustration(floatAnimation: _floatController),
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
                        backgroundColor: AppColors.accent,
                        foregroundColor: isDark ? const Color(0xFF020617) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.large,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.outfit(
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
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 14,
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
        color: isSelected ? AppColors.accent : const Color(0xFF94A3B8).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// ILLUSTRATIONS FOR INTRO SLIDES

class _SafeToSpendIllustration extends StatelessWidget {
  final Animation<double> floatAnimation;
  const _SafeToSpendIllustration({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const emeraldColor = Color(0xFF10B981);
    const emeraldAccentColor = Color(0xFF34D399);

    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        final double translation = floatAnimation.value * 12.0 - 6.0;
        return Transform.translate(
          offset: Offset(0, translation),
          child: Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  emeraldColor.withValues(alpha: 0.15),
                  Colors.teal.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: emeraldColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: emeraldColor.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: emeraldColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Safe Limit',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: emeraldAccentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.check_circle_outline_rounded, color: emeraldColor, size: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs. 1,450',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available to spend today',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanningIllustration extends StatefulWidget {
  const _PlanningIllustration();

  @override
  State<_PlanningIllustration> createState() => _PlanningIllustrationState();
}

class _PlanningIllustrationState extends State<_PlanningIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Budget Box
          Transform.translate(
            offset: const Offset(-20, -20),
            child: Opacity(
              opacity: 0.8,
              child: Container(
                width: 180,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budgets', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressController.value * 0.65,
                          color: Colors.blueAccent,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text('65% Consumed', style: GoogleFonts.outfit(fontSize: 8, color: Colors.blueAccent)),
                  ],
                ),
              ),
            ),
          ),

          // Foreground Goal Box
          Transform.translate(
            offset: const Offset(20, 20),
            child: Container(
              width: 180,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.06),
                    blurRadius: 16,
                  )
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Savings Target', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
                      const Icon(Icons.stars, color: Colors.amber, size: 14),
                    ],
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final pct = (_progressController.value * 85).toStringAsFixed(0);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$pct% Complete', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Car Goal', style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionIllustration extends StatefulWidget {
  const _SubscriptionIllustration();

  @override
  State<_SubscriptionIllustration> createState() => _SubscriptionIllustrationState();
}

class _SubscriptionIllustrationState extends State<_SubscriptionIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.04);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 220,
              height: 130,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.05),
                    blurRadius: 20,
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
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Netflix Premium',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'Rs. 649',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.alarm, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Renews in 2 Days',
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PredictionsIllustration extends StatefulWidget {
  const _PredictionsIllustration();

  @override
  State<_PredictionsIllustration> createState() => _PredictionsIllustrationState();
}

class _PredictionsIllustrationState extends State<_PredictionsIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 240,
      height: 150,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Spend Velocity', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Predictions',
                  style: GoogleFonts.outfit(fontSize: 8, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 60,
            child: AnimatedBuilder(
              animation: _lineController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LineChartPainter(_lineController.value),
                  size: const Size(200, 60),
                );
              },
            ),
          ),
          const Spacer(),
          Text(
            'Remaining budget will last approx. 18 days',
            style: GoogleFonts.outfit(fontSize: 9, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final double progress;
  _LineChartPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.9,
      size.width * 0.75,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.1);

    final pms = path.computeMetrics().first;
    final extract = pms.extractPath(0, pms.length * progress);

    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ExportIllustration extends StatelessWidget {
  final Animation<double> floatAnimation;
  const _ExportIllustration({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        final double translation = floatAnimation.value * -8.0 + 4.0;
        return Transform.translate(
          offset: Offset(0, translation),
          child: Container(
            width: 230,
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
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
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Account Statement',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Icon(Icons.cloud_done, color: Colors.blueAccent, size: 16),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Name: John Doe\nEmail: john@doe.com',
                      style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PDF Exporter',
                        style: GoogleFonts.outfit(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
