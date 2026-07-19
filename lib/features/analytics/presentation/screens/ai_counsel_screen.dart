import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? prefixLabel; // e.g. "YES, IF"
  final bool isOutline;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.prefixLabel,
    this.isOutline = false,
  });
}

class AiCounselScreen extends ConsumerStatefulWidget {
  const AiCounselScreen({super.key});

  @override
  ConsumerState<AiCounselScreen> createState() => _AiCounselScreenState();
}

class _AiCounselScreenState extends ConsumerState<AiCounselScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNudge();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialNudge() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dashboardData = ref.read(dashboardDataProvider).value;
      final budgetProgress = ref.read(budgetProgressProvider).value;
      final subscriptions = ref.read(subscriptionsStreamProvider).value ?? [];

      if (dashboardData != null) {
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
        );

        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: nudge,
              isUser: false,
              isOutline: false,
            ));
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: "Good evening. Your ledger is active. Ask me any question about affordability or pacing your daily limits.",
              isUser: false,
              isOutline: false,
            ));
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Hello! I am ready to advise you on your budgets. Ask me about any spending or purchase decision.",
            isUser: false,
            isOutline: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendQuery(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      isOutline: true,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _queryController.clear();
    _scrollToBottom();

    try {
      final dashboardData = ref.read(dashboardDataProvider).value;
      final budgetProgress = ref.read(budgetProgressProvider).value;
      final subscriptions = ref.read(subscriptionsStreamProvider).value ?? [];

      final double safeToSpend = dashboardData?.safeToSpend ?? 0.0;
      final double totalBalance = dashboardData?.totalBalance ?? 0.0;
      final double totalLimit = budgetProgress?.totalLimit ?? 0.0;
      final double totalSpent = budgetProgress?.totalSpent ?? 0.0;

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
        query: text,
        safeToSpend: safeToSpend,
        totalBalance: totalBalance,
        totalLimit: totalLimit,
        totalSpent: totalSpent,
        upcomingSubscriptions: upcomingSubs,
        categoryProgresses: categoryProgress,
      );

      if (mounted) {
        // Parse if response has "yes, if" pattern to split prefix title
        String cleanResponse = response;
        String? prefix;
        if (response.toLowerCase().startsWith("yes, if")) {
          prefix = "YES, IF";
          cleanResponse = response.substring(7).trim();
          if (cleanResponse.startsWith(":") || cleanResponse.startsWith(",")) {
            cleanResponse = cleanResponse.substring(1).trim();
          }
        } else if (response.toLowerCase().startsWith("no, because")) {
          prefix = "NO, BECAUSE";
          cleanResponse = response.substring(11).trim();
          if (cleanResponse.startsWith(":") || cleanResponse.startsWith(",")) {
            cleanResponse = cleanResponse.substring(1).trim();
          }
        }

        setState(() {
          _messages.add(ChatMessage(
            text: cleanResponse,
            isUser: false,
            prefixLabel: prefix,
            isOutline: prefix != null,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Sorry, I encountered an issue accessing your local ledger data: $e",
            isUser: false,
            isOutline: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header Bar matching Mockup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI counsel',
                          style: GoogleFonts.fraunces(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Ask about affordability, pacing, or spending',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1, thickness: 0.5),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    // Typing indicator bubble
                    return _buildTypingIndicator();
                  }

                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Horizontal Suggestion Chips above the Input Box
            if (!_isLoading) _buildSuggestionChips(),

            // Bottom Input Box Area
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isRight = msg.isUser;
    
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: msg.isOutline ? Colors.transparent : (isRight ? AppColors.primary : AppColors.surface),
          borderRadius: BorderRadius.circular(18),
          border: msg.isOutline ? Border.all(color: AppColors.primary, width: 1.2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.prefixLabel != null) ...[
              Text(
                msg.prefixLabel!,
                style: GoogleFonts.fraunces(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: isRight && !msg.isOutline ? AppColors.background : AppColors.primaryText,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Can I afford a ₹3,000 dinner this weekend?',
      'What if I skip eating out next week instead?',
      'Can I afford ₹1,500 shopping?',
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return GestureDetector(
            onTap: () => _sendQuery(text),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.55), width: 1.0),
                borderRadius: BorderRadius.circular(18),
                color: Colors.transparent,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: TextField(
                controller: _queryController,
                onSubmitted: _sendQuery,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Ask a follow-up...',
                  hintStyle: TextStyle(
                    color: AppColors.secondaryText.withOpacity(0.5),
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendQuery(_queryController.text),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.background,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
