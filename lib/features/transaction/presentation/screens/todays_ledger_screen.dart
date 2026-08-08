import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';

class TodaysLedgerScreen extends ConsumerStatefulWidget {
  const TodaysLedgerScreen({super.key});

  @override
  ConsumerState<TodaysLedgerScreen> createState() => _TodaysLedgerScreenState();
}

class _TodaysLedgerScreenState extends ConsumerState<TodaysLedgerScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    final dateStr = DateFormat('d MMM').format(date).toUpperCase();
    if (txDate == today) return 'TODAY, $dateStr';
    if (txDate == yesterday) return 'YESTERDAY, $dateStr';
    return DateFormat('EEEE, d MMM').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(preferencesProvider).currency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium AppBar Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Screen Title (on the left)
                  Expanded(
                    child: Text(
                      "Ledger History",
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Search toggle button
                  BouncyButton(
                    onTap: _toggleSearch,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isSearching
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSearching ? AppColors.primary : AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isSearching ? Icons.close_rounded : Icons.search_rounded,
                        color: _isSearching ? AppColors.primary : AppColors.primaryText,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Circular Close (Cross) button
                  BouncyButton(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.primaryText,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Search field (collapsible)
              if (_isSearching) ...[
                TextFormField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 18),
              ],

              // Transactions List Body
              Expanded(
                child: transactionsAsync.when(
                  loading: () => ListView(
                    children: const [
                      SkeletonLoader.listTile(),
                      VSpace.md,
                      SkeletonLoader.listTile(),
                    ],
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                  data: (txs) {
                    // Filter transactions matching search query (all dates included)
                    final filtered = txs.where((tx) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          (tx.note?.toLowerCase() ?? '').contains(_searchQuery) ||
                          tx.category.name.toLowerCase().contains(_searchQuery) ||
                          tx.amount.toString().contains(_searchQuery);
                      return matchesSearch;
                    }).toList();

                    // Sort: newest first
                    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No transactions recorded.'
                              : 'No matching entries found.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      );
                    }

                    // Group by Date
                    final Map<DateTime, List<Transaction>> grouped = {};
                    for (final tx in filtered) {
                      final dateOnly = DateTime(
                        tx.transactionDate.year,
                        tx.transactionDate.month,
                        tx.transactionDate.day,
                      );
                      grouped.putIfAbsent(dateOnly, () => []).add(tx);
                    }
                    final sortedDates = grouped.keys.toList();
                    sortedDates.sort((a, b) => b.compareTo(a));

                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        ref.invalidate(transactionsStreamProvider);
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final dayTxs = grouped[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 14, bottom: 8),
                                child: Text(
                                  _getDateHeader(date),
                                  style: GoogleFonts.fraunces(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.disabledText,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border, width: 1.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: dayTxs.map<Widget>((tx) {
                                    final isExpense = tx.type == TransactionType.expense;
                                    final prefix = isExpense ? '-' : '+';
                                    final amountText = '$prefix$currency${tx.amount.toStringAsFixed(0)}';
                                    final formatTime = DateFormat('h:mm a').format(tx.transactionDate);

                                    return Column(
                                      children: [
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: tx.isEncrypted
                                              ? () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Unlock Zero-Knowledge Sync to view/edit this entry.'),
                                                      action: SnackBarAction(
                                                        label: 'Unlock',
                                                        textColor: AppColors.primary,
                                                        onPressed: () {
                                                          showModalBottomSheet(
                                                            context: context,
                                                            isDismissible: true,
                                                            enableDrag: true,
                                                            isScrollControlled: true,
                                                            backgroundColor: AppColors.background,
                                                            shape: const RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.zero,
                                                            ),
                                                            builder: (context) => const PinUnlockSheet(),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                }
                                              : () => context.push('/add-transaction', extra: tx),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: isExpense
                                                        ? (tx.isSplit ? const Color(0xFFC8A05B) : AppColors.expense)
                                                        : AppColors.income,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              tx.note ?? tx.category.name,
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                              style: AppTextStyles.body.copyWith(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          if (tx.isEncrypted) ...[
                                                            const SizedBox(width: 6),
                                                            const Icon(
                                                              Icons.lock_outline_rounded,
                                                              size: 11,
                                                              color: AppColors.disabledText,
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${tx.isSplit ? "Split" : tx.category.name}  •  $formatTime',
                                                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  amountText,
                                                  style: AppTextStyles.mono.copyWith(
                                                    fontSize: 14,
                                                    color: isExpense ? AppColors.expense : AppColors.income,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (dayTxs.last != tx)
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
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
