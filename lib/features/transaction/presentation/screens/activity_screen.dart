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
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import 'split_ledger_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _showSplits = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  String _formatStat(double value) {
    final absVal = value.abs();
    if (absVal >= 100000) {
      return '${(absVal / 1000.0).toStringAsFixed(0)}k';
    } else if (absVal >= 1000) {
      return '${(absVal / 1000.0).toStringAsFixed(1)}k';
    }
    return absVal.toStringAsFixed(0);
  }

  Future<void> _exportPdf(List<Transaction> txs, String currency) async {
    final messenger = ScaffoldMessenger.of(context);
    if (txs.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No transactions to export.')));
      return;
    }
    try {
      final userAsync = ref.read(userProfileStreamProvider);
      final user = userAsync.value;
      final name = user?.name ?? 'User';
      final email = user?.email ?? 'user@fintrack.app';
      await ExportService.exportTransactionsToPdf(txs, currency, name, email);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  Future<void> _exportCsv(List<Transaction> txs) async {
    final messenger = ScaffoldMessenger.of(context);
    if (txs.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No transactions to export.')));
      return;
    }
    try {
      await ExportService.exportTransactionsToCsv(txs);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final userAsync = ref.watch(userProfileStreamProvider);
    final currency = ref.watch(preferencesProvider).currency;

    final userInitials = userAsync.maybeWhen(
      data: (profile) {
        if (profile != null && profile.name.trim().isNotEmpty) {
          final parts = profile.name.trim().split(' ');
          if (parts.length >= 2) {
            return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          }
          return parts[0][0].toUpperCase();
        }
        return 'U';
      },
      orElse: () => 'U',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Mockup Header Block
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gold FT badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'FT',
                      style: GoogleFonts.fraunces(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.background,
                      ),
                    ),
                  ),

                  // Search toggle & profile avatar group
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                        icon: Icon(
                          _isSearching ? Icons.close_rounded : Icons.search_rounded,
                          color: AppColors.primaryText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      BouncyButton(
                        onTap: () => context.push('/settings'),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 1.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              userInitials,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Ledger',
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 18),

              // Segmented Slide Controller: Activity vs Splits
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showSplits = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_showSplits ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Activity',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: !_showSplits ? AppColors.background : AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showSplits = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _showSplits ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Splits',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _showSplits ? AppColors.background : AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search field (collapsible)
              if (_isSearching) ...[
                TextFormField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search Swiggy, Freelance, Rent...',
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
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Main Body Layout
              Expanded(
                child: _showSplits
                    ? const SplitLedgerScreen(isEmbedded: true)
                    : transactionsAsync.when(
                        loading: () => ListView(
                          children: const [
                            SkeletonLoader.listTile(),
                            VSpace.md,
                            SkeletonLoader.listTile(),
                          ],
                        ),
                        error: (err, stack) => Center(child: Text('Error: $err')),
                        data: (txs) {
                          // Filter lists
                          final filtered = txs.where((tx) {
                            final matchesSearch = _searchQuery.isEmpty ||
                                (tx.note?.toLowerCase() ?? '').contains(_searchQuery) ||
                                tx.category.name.toLowerCase().contains(_searchQuery) ||
                                tx.amount.toString().contains(_searchQuery);
                            return matchesSearch;
                          }).toList();

                          // Calculate stats
                          final totalIncome = filtered
                              .where((tx) => tx.type == TransactionType.income)
                              .fold<double>(0.0, (sum, tx) => sum + tx.amount);

                          final totalExpenses = filtered
                              .where((tx) => tx.type == TransactionType.expense)
                              .fold<double>(0.0, (sum, tx) => sum + tx.amount);

                          final net = totalIncome - totalExpenses;

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
                          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Triple stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'INCOME',
                                      '$currency${_formatStat(totalIncome)}',
                                      AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      'EXPENSES',
                                      '$currency${_formatStat(totalExpenses)}',
                                      AppColors.expense,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      'NET',
                                      '${net >= 0 ? "+" : "-"}$currency${_formatStat(net)}',
                                      net >= 0 ? AppColors.income : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Down arrows outlined export buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: BouncyButton(
                                      onTap: () => _exportPdf(filtered, currency),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primary.withOpacity(0.4),
                                            width: 1.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '↓ Export PDF',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: BouncyButton(
                                      onTap: () => _exportCsv(filtered),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primary.withOpacity(0.4),
                                            width: 1.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '↓ Export CSV',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Activity Logs
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No ledger entries found.',
                                          style: AppTextStyles.bodySecondary,
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: AppColors.primary,
                                        backgroundColor: AppColors.surface,
                                        onRefresh: () async {
                                          ref.invalidate(transactionsStreamProvider);
                                        },
                                        child: ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          itemCount: sortedDates.length,
                                          itemBuilder: (context, dateIndex) {
                                            final date = sortedDates[dateIndex];
                                            final dayTxs = grouped[date]!;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Date header (expressive Fraunces serif)
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
                                                
                                                // Day Card list container
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
                                                            onTap: () => context.push('/transactions/add', extra: tx),
                                                            child: Padding(
                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                              child: Row(
                                                                children: [
                                                                  // Mini color square block
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
                                                                            Text(
                                                                              tx.note ?? tx.category.name,
                                                                              style: AppTextStyles.body.copyWith(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 14,
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
                                                                  // Monospace amount
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
                                      ),
                              ),
                            ],
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

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.disabledText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.mono.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
