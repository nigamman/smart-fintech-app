import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../commons/widgets/empty_state.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class SplitLedgerScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const SplitLedgerScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<SplitLedgerScreen> createState() => _SplitLedgerScreenState();
}

class _SplitLedgerScreenState extends ConsumerState<SplitLedgerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _settleAllWithFriend(List<Transaction> friendTransactions, String friendName) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(transactionControllerProvider.notifier);

    // Filter to unpaid transactions
    final unpaid = friendTransactions.where((tx) => !tx.isSplitPaid).toList();
    if (unpaid.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle Balance with $friendName?'),
        content: Text('Are you sure you want to mark all ${unpaid.length} pending splits with $friendName as repaid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.income),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (final tx in unpaid) {
          // 1. Mark original split transaction as paid
          await notifier.updateTransaction(
            id: tx.id,
            amount: tx.amount,
            type: tx.type,
            category: tx.category,
            note: tx.note,
            date: tx.transactionDate,
            createdAt: tx.createdAt,
            isSplit: true,
            splitWith: tx.splitWith,
            splitPercentage: tx.splitPercentage,
            isSplitPaid: true,
          );

          // 2. Calculate friend's share
          final friendShare = tx.amount * ((tx.splitPercentage ?? 50.0) / 100);

          // 3. Create a new repayment income transaction to reflect cash flow
          final txName = tx.note != null && tx.note!.isNotEmpty
              ? tx.note!
              : tx.category.name[0].toUpperCase() + tx.category.name.substring(1);
          await notifier.addTransaction(
            amount: friendShare,
            type: TransactionType.income,
            category: TransactionCategory.other,
            note: 'Repayment: $txName ($friendName)',
            date: DateTime.now(),
          );
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('All balances settled with $friendName!')),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error settling balance: $e')),
        );
      }
    }
  }

  void _showFriendDetailsSheet(
    BuildContext parentContext,
    String friendName,
    List<Transaction> txList,
    double outstanding,
    String currency,
  ) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sbCtx, setModalState) {
            try {
              return Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom: MediaQuery.of(sbCtx).viewInsets.bottom + 24,
                ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          friendName,
                          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (outstanding > 0)
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sbCtx);
                              await _settleAllWithFriend(txList, friendName);
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Settle All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.income,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    VSpace.sm,
                    Text(
                      outstanding > 0
                          ? 'Owes you $currency${outstanding.toStringAsFixed(0)} in total'
                          : 'All balances settled',
                      style: AppTextStyles.body.copyWith(
                        color: outstanding > 0 ? AppColors.income : AppColors.secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    VSpace.lg,
                    const Divider(height: 1),
                    VSpace.md,
                    Text(
                      'BILL DETAILS',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    VSpace.md,
                    SizedBox(
                      height: 300,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: txList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (itemCtx, index) {
                          final tx = txList[index];
                          final friendOwes = tx.amount * ((tx.splitPercentage ?? 50.0) / 100);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              tx.note != null && tx.note!.isNotEmpty
                                  ? tx.note!
                                  : tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy').format(tx.transactionDate),
                              style: AppTextStyles.caption,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currency${friendOwes.toStringAsFixed(0)}',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: tx.isSplitPaid ? AppColors.secondaryText : AppColors.income,
                                    decoration: tx.isSplitPaid ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                Text(
                                  tx.isSplitPaid ? 'Repaid' : 'Pending',
                                  style: AppTextStyles.caption.copyWith(
                                    color: tx.isSplitPaid ? AppColors.secondaryText : AppColors.warning,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } catch (e, stack) {
              debugPrint('Error inside StatefulBuilder sheet content: $e\n$stack');
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Error displaying details:',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  String _formatAmount(double val) {
    return NumberFormat('#,##0', 'en_US').format(val.abs());
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(preferencesProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyContent = transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (transactions) {
        final splitTransactions = transactions.where((tx) => tx.isSplit).toList();

        if (splitTransactions.isEmpty) {
          return const EmptyState(
            title: 'No Split Bills',
            subtitle: 'Add an expense and toggle "Split this bill" to get started.',
            icon: Icons.splitscreen_rounded,
          );
        }

        // Grouping by friend
        final Map<String, List<Transaction>> friendsLedger = {};
        for (final tx in splitTransactions) {
          final friend = tx.splitWith ?? 'Unknown Friend';
          if (!friendsLedger.containsKey(friend)) {
            friendsLedger[friend] = [];
          }
          friendsLedger[friend]!.add(tx);
        }

        // Calculate outstanding amounts per friend
        final List<Map<String, dynamic>> friendBalances = [];
        double othersOweYou = 0.0;

        friendsLedger.forEach((friend, txList) {
          double outstanding = 0.0;
          for (final tx in txList) {
            if (!tx.isSplitPaid) {
              final share = tx.amount * ((tx.splitPercentage ?? 50.0) / 100);
              if (tx.type == TransactionType.expense) {
                outstanding += share;
              } else {
                outstanding -= share;
              }
            }
          }
          if (outstanding > 0) {
            othersOweYou += outstanding;
          }
          friendBalances.add({
            'name': friend,
            'transactions': txList,
            'outstanding': outstanding,
          });
        });

        // Sort friend balances by outstanding amount (highest first)
        friendBalances.sort((a, b) => b['outstanding'].compareTo(a['outstanding']));

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card (Others owe you only)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Others owe you',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$currency${_formatAmount(othersOweYou)}',
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title "ROOMMATES" (expressive serif)
              Text(
                'FRIENDS',
                style: GoogleFonts.fraunces(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.disabledText,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Roommates list container card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: friendBalances.map<Widget>((item) {
                    final name = item['name'] as String;
                    final outstanding = item['outstanding'] as double;
                    final txList = item['transactions'] as List<Transaction>;

                    final isOwed = outstanding > 0;
                    final isOwes = outstanding < 0;
                    final String statusText = isOwed
                        ? 'Owes you'
                        : (isOwes ? 'You owe' : 'Settled');
                    final Color statusColor = isOwed
                        ? AppColors.income
                        : (isOwes ? AppColors.expense : AppColors.disabledText);

                    final prefix = isOwed ? '+' : (isOwes ? '-' : '');
                    final amountText = '$prefix$currency${_formatAmount(outstanding)}';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              // Avatar circle with outline
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 1.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name & Status Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      statusText,
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Amount (tabulated monospace)
                              Text(
                                amountText,
                                style: AppTextStyles.mono.copyWith(
                                  fontSize: 14.5,
                                  color: outstanding > 0
                                      ? AppColors.income
                                      : (outstanding < 0 ? AppColors.expense : AppColors.disabledText),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Settle outlined button
                              BouncyButton(
                                onTap: () => _settleAllWithFriend(txList, name),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary, width: 1.0),
                                  ),
                                  child: Text(
                                    'Settle',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (friendBalances.last != item)
                          Container(
                            height: 0.5,
                            color: AppColors.border,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Ledger'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: bodyContent,
      ),
    );
  }
}
