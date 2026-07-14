import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _searchQuery = '';
  TransactionCategory? _selectedCategory;

  void _showExportDialog(BuildContext context, WidgetRef ref, List<dynamic> txs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transactions'),
        content: const Text('Choose your preferred file format to save or share your transaction history.'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              if (txs.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No transactions to export.')),
                );
                return;
              }
              try {
                // Map dynamic list to Transaction list
                final typedTxs = txs.cast<Transaction>();
                await ExportService.exportTransactionsToCsv(typedTxs);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to export CSV: $e')),
                );
              }
            },
            icon: const Icon(Icons.table_rows_rounded),
            label: const Text('Export CSV'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              if (txs.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No transactions to export.')),
                );
                return;
              }
              try {
                final currency = ref.read(preferencesProvider).currency;
                final userAsync = ref.read(userProfileStreamProvider);
                final user = userAsync.value;
                final name = user?.name ?? 'User';
                final email = user?.email ?? 'user@fintrack.app';
                final typedTxs = txs.cast<Transaction>();
                await ExportService.exportTransactionsToPdf(typedTxs, currency, name, email);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to export PDF: $e')),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) return 'Today';
    if (txDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMMM yyyy').format(date);
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return Icons.work_outline_rounded;
      case TransactionCategory.freelance:
        return Icons.devices_rounded;
      case TransactionCategory.investment:
        return Icons.trending_up_rounded;
      case TransactionCategory.gift:
        return Icons.card_giftcard_rounded;
      case TransactionCategory.food:
        return Icons.restaurant_rounded;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_outlined;
      case TransactionCategory.travel:
        return Icons.flight_takeoff_rounded;
      case TransactionCategory.bills:
        return Icons.receipt_long_rounded;
      case TransactionCategory.entertainment:
        return Icons.sports_esports_rounded;
      case TransactionCategory.health:
        return Icons.medical_services_outlined;
      case TransactionCategory.education:
        return Icons.school_outlined;
      case TransactionCategory.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              Text(
                'Filter by Category',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: TransactionCategory.values.length,
                  itemBuilder: (context, index) {
                    final category = TransactionCategory.values[index];
                    final isSelected = _selectedCategory == category;
                    final icon = _getCategoryIcon(category);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.2)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.accent : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? AppColors.accent
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category.name[0].toUpperCase() + category.name.substring(1),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.accent
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          transactionsAsync.maybeWhen(
            data: (txs) => IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _showExportDialog(context, ref, txs),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Search Swiggy, Salary, Coffee...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: _selectedCategory != null ? AppColors.accent : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                      tooltip: 'Filter by category',
                      onPressed: _showCategoriesBottomSheet,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
                if (_selectedCategory != null) ...[
                  VSpace.sm,
                  Row(
                    children: [
                      InputChip(
                        label: Text(
                          'Category: ${_selectedCategory!.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        backgroundColor: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          VSpace.md,

          // Transactions Timeline Group list
          Expanded(
            child: transactionsAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  SkeletonLoader.listTile(),
                  VSpace.md,
                  SkeletonLoader.listTile(),
                  VSpace.md,
                  SkeletonLoader.listTile(),
                ],
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (txs) {
                // Apply searches & category filters
                var filtered = txs.where((tx) {
                  final matchesCat = _selectedCategory == null || tx.category == _selectedCategory;
                  final noteStr = tx.note?.toLowerCase() ?? '';
                  final catStr = tx.category.name.toLowerCase();
                  final amountStr = tx.amount.toString();
                  final matchesSearch = _searchQuery.isEmpty ||
                      noteStr.contains(_searchQuery) ||
                      catStr.contains(_searchQuery) ||
                      amountStr.contains(_searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                          VSpace.md,
                          Text('No matching activity logs found.', style: AppTextStyles.bodySecondary),
                        ],
                      ),
                    ),
                  );
                }

                // Group by DateOnly representation
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

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(transactionsStreamProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final date = sortedDates[dateIndex];
                      final dayTxs = grouped[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              _getDateHeader(date),
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131B2E) : Colors.white,
                              borderRadius: AppRadius.large,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: dayTxs.map<Widget>((tx) {
                                return TransactionTile(
                                  title: tx.note ?? tx.category.name,
                                  category: tx.category.name,
                                  amount: tx.amount,
                                  date: tx.transactionDate,
                                  type: tx.type,
                                  onTap: () => context.push('/add-transaction', extra: tx),
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
    );
  }
}
