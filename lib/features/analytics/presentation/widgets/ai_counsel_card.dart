import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class AiCounselCard extends ConsumerStatefulWidget {
  const AiCounselCard({super.key});

  @override
  ConsumerState<AiCounselCard> createState() => _AiCounselCardState();
}

class _AiCounselCardState extends ConsumerState<AiCounselCard> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _nudgeText;
  bool _isLoadingNudge = true;
  String? _nudgeError;

  String? _userQuestion;
  String? _aiResponse;
  bool _isEvaluatingAffordability = false;

  @override
  void initState() {
    super.initState();
    // Load nudge once post frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProactiveNudge();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProactiveNudge() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNudge = true;
      _nudgeError = null;
    });

    try {
      final dashboardData = ref.read(dashboardDataProvider).value;
      final budgetProgress = ref.read(budgetProgressProvider).value;
      final subscriptions = ref.read(subscriptionsStreamProvider).value ?? [];
      final preferences = ref.read(preferencesProvider);

      if (dashboardData == null) {
        throw Exception('Dashboard data not loaded yet.');
      }

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      final upcomingSubs = subscriptions.where((sub) {
        return sub.nextBillingDate.isAfter(now) && sub.nextBillingDate.isBefore(nextWeek);
      }).map((sub) => {
        'name': sub.name,
        'amount': sub.amount,
      }).toList();

      final categoryProgress = budgetProgress?.categoryProgresses.map((c) => {
        'category': c.category.name,
        'spent': c.spent,
        'limit': c.limit,
      }).toList() ?? [];

      final nudge = await GeminiService.generateProactiveNudge(
        safeToSpend: dashboardData.safeToSpend,
        totalBalance: dashboardData.totalBalance,
        totalLimit: budgetProgress?.totalLimit ?? 0.0,
        totalSpent: budgetProgress?.totalSpent ?? 0.0,
        upcomingSubscriptions: upcomingSubs,
        categoryProgresses: categoryProgress,
        apiKey: preferences.geminiApiKey,
      );

      if (mounted) {
        setState(() {
          _nudgeText = nudge;
          _isLoadingNudge = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nudgeError = 'Unable to compile prompt context: $e';
          _isLoadingNudge = false;
        });
      }
    }
  }

  Future<void> _askAffordability(String question) async {
    if (question.trim().isEmpty) return;
    
    setState(() {
      _userQuestion = question;
      _aiResponse = null;
      _isEvaluatingAffordability = true;
    });

    FocusScope.of(context).unfocus();
    _queryController.clear();

    // Scroll to show progress loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final dashboardData = ref.read(dashboardDataProvider).value;
      final budgetProgress = ref.read(budgetProgressProvider).value;
      final subscriptions = ref.read(subscriptionsStreamProvider).value ?? [];
      final preferences = ref.read(preferencesProvider);

      if (dashboardData == null) {
        throw Exception('Dashboard data not loaded.');
      }

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      final upcomingSubs = subscriptions.where((sub) {
        return sub.nextBillingDate.isAfter(now) && sub.nextBillingDate.isBefore(nextWeek);
      }).map((sub) => {
        'name': sub.name,
        'amount': sub.amount,
      }).toList();

      final categoryProgress = budgetProgress?.categoryProgresses.map((c) => {
        'category': c.category.name,
        'spent': c.spent,
        'limit': c.limit,
      }).toList() ?? [];

      final response = await GeminiService.getAffordabilityAdvice(
        query: question,
        safeToSpend: dashboardData.safeToSpend,
        totalBalance: dashboardData.totalBalance,
        totalLimit: budgetProgress?.totalLimit ?? 0.0,
        totalSpent: budgetProgress?.totalSpent ?? 0.0,
        upcomingSubscriptions: upcomingSubs,
        categoryProgresses: categoryProgress,
        apiKey: preferences.geminiApiKey,
      );

      if (mounted) {
        setState(() {
          _aiResponse = response;
          _isEvaluatingAffordability = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponse = 'Error evaluating affordability: $e';
          _isEvaluatingAffordability = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.purpleAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Financial Counsel',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ref.watch(preferencesProvider).geminiApiKey.isNotEmpty
                          ? 'Gemini 1.5 Active'
                          : 'Counsel Demo Mode',
                      style: AppTextStyles.caption.copyWith(color: Colors.purpleAccent),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.grey),
                onPressed: _loadProactiveNudge,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conversation Area
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Proactive Nudge Bubble
                  _buildAiBubble(
                    content: _isLoadingNudge
                        ? 'Evaluating your ledger trends...'
                        : (_nudgeError ?? _nudgeText ?? 'No advice generated yet.'),
                    isLoading: _isLoadingNudge,
                    isDark: isDark,
                  ),

                  // 2. User Question Bubble
                  if (_userQuestion != null) ...[
                    const SizedBox(height: 12),
                    _buildUserBubble(_userQuestion!, isDark),
                  ],

                  // 3. AI Reply Bubble
                  if (_isEvaluatingAffordability || _aiResponse != null) ...[
                    const SizedBox(height: 12),
                    _buildAiBubble(
                      content: _isEvaluatingAffordability
                          ? 'Reviewing budgets and Safe-to-Spend...'
                          : _aiResponse!,
                      isLoading: _isEvaluatingAffordability,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Suggestion Chips (only when not loading or custom question)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSuggestionChip('Can I afford ₹3,000 dinner tonight?', isDark),
                const SizedBox(width: 8),
                _buildSuggestionChip('Can I afford ₹2,000 shopping?', isDark),
                const SizedBox(width: 8),
                _buildSuggestionChip('Can I afford a ₹5,000 phone?', isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Input textfield
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  onSubmitted: _askAffordability,
                  decoration: InputDecoration(
                    hintText: 'Ask: Can I afford ₹2,000 shopping?',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.accent,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.black),
                  onPressed: () => _askAffordability(_queryController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble({
    required String content,
    required bool isLoading,
    required bool isDark,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    content,
                    style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              )
            : Text(
                content,
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 13, height: 1.4),
              ),
      ),
    );
  }

  Widget _buildUserBubble(String text, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.purpleAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String query, bool isDark) {
    final cleanQuery = query.replaceAll('Can I afford ', '').replaceAll('?', '');
    return ActionChip(
      label: Text(
        cleanQuery,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      onPressed: () => _askAffordability(query),
    );
  }
}
