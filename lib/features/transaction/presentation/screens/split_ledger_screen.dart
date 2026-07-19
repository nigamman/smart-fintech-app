import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

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
  const SplitLedgerScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(preferencesProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Ledger'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'Balances'),
            Tab(text: 'Split History'),
          ],
        ),
      ),
      body: transactionsAsync.when(
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
          double totalOwedToMe = 0.0;

          friendsLedger.forEach((friend, txList) {
            double outstanding = 0.0;
            for (final tx in txList) {
              if (!tx.isSplitPaid) {
                final friendOwes = tx.amount * ((tx.splitPercentage ?? 50.0) / 100);
                outstanding += friendOwes;
              }
            }
            totalOwedToMe += outstanding;
            friendBalances.add({
              'name': friend,
              'transactions': txList,
              'outstanding': outstanding,
            });
          });

          // Sort friend balances by outstanding amount (highest first)
          friendBalances.sort((a, b) => b['outstanding'].compareTo(a['outstanding']));

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. BALANCES TAB
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Total Summary Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                            : [const Color(0xFFEEF2FF), const Color(0xFFFAE8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: isDark ? const Color(0xFF312E81) : const Color(0xFFC7D2FE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL OWED TO YOU',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currency${totalOwedToMe.toStringAsFixed(0)}',
                          style: AppTextStyles.h1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From ${friendBalances.where((b) => b['outstanding'] > 0).length} friends',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VSpace.xl,
                  Text(
                    'FRIENDS',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.secondaryText,
                    ),
                  ),
                  VSpace.md,
                  if (friendBalances.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No friends added to splits yet.',
                          style: AppTextStyles.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friendBalances.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final item = friendBalances[i];
                        final name = item['name'] as String;
                        final outstanding = item['outstanding'] as double;
                        final list = item['transactions'] as List<Transaction>;

                        return InkWell(
                          onTap: () => _showFriendDetailsSheet(context, name, list, outstanding, currency),
                          borderRadius: AppRadius.medium,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131B2E) : Colors.white,
                              borderRadius: AppRadius.medium,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${list.length} shared bill${list.length > 1 ? 's' : ''}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      outstanding > 0 ? '$currency${outstanding.toStringAsFixed(0)}' : 'Settled',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: outstanding > 0 ? AppColors.income : AppColors.secondaryText,
                                      ),
                                    ),
                                    if (outstanding > 0)
                                      Text(
                                        'Owes you',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.income, fontSize: 10),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.secondaryText),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              // 2. SPLIT HISTORY TAB
              ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: splitTransactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (historyCtx, i) {
                  final tx = splitTransactions[i];
                  final friendOwes = tx.amount * ((tx.splitPercentage ?? 50.0) / 100);
                  final label = '${tx.splitWith ?? "Someone"} owes';

                  return TransactionTile(
                    title: tx.note != null && tx.note!.isNotEmpty
                        ? tx.note!
                        : tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                    category: '$label $currency${friendOwes.toStringAsFixed(0)}',
                    amount: tx.amount,
                    date: tx.transactionDate,
                    type: tx.type,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
