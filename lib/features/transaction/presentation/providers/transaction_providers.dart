import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/datasources/transaction_local_datasource_impl.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/datasources/transaction_remote_datasource_impl.dart';
import '../../data/repositories/transaction_repositories_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRemoteDataSourceProvider = Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSourceImpl();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    remoteDataSource: ref.watch(transactionRemoteDataSourceProvider),
    localDataSource: ref.watch(transactionLocalDataSourceProvider),
  );
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(transactionRepositoryProvider).getTransactions(user.id);
});

class TransactionFilters {
  final String searchQuery;
  final TransactionCategory? category;
  final TransactionType? type;
  final DateTimeRange? dateRange;

  const TransactionFilters({
    this.searchQuery = '',
    this.category,
    this.type,
    this.dateRange,
  });

  TransactionFilters copyWith({
    String? searchQuery,
    TransactionCategory? category,
    TransactionType? type,
    DateTimeRange? dateRange,
    bool clearCategory = false,
    bool clearType = false,
    bool clearDateRange = false,
  }) {
    return TransactionFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }
}

final transactionFiltersProvider = NotifierProvider<TransactionFiltersNotifier, TransactionFilters>(
  TransactionFiltersNotifier.new,
);

class TransactionFiltersNotifier extends Notifier<TransactionFilters> {
  @override
  TransactionFilters build() {
    return const TransactionFilters();
  }

  void updateFilters(TransactionFilters Function(TransactionFilters) update) {
    state = update(state);
  }
}

final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final filters = ref.watch(transactionFiltersProvider);

  return transactionsAsync.whenData((transactions) {
    return transactions.where((tx) {
      // Search filter
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        final note = tx.note?.toLowerCase() ?? '';
        final categoryName = tx.category.name.toLowerCase();
        if (!note.contains(query) && !categoryName.contains(query)) {
          return false;
        }
      }

      // Category filter
      if (filters.category != null && tx.category != filters.category) {
        return false;
      }

      // Type filter
      if (filters.type != null && tx.type != filters.type) {
        return false;
      }

      // Date range filter
      if (filters.dateRange != null) {
        final txDate = tx.transactionDate;
        final start = DateUtils.dateOnly(filters.dateRange!.start);
        final end = DateUtils.dateOnly(filters.dateRange!.end);
        final txDateOnly = DateUtils.dateOnly(txDate);
        if (txDateOnly.isBefore(start) || txDateOnly.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

final transactionControllerProvider = AsyncNotifierProvider<TransactionController, void>(
  TransactionController.new,
);

class TransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    String? note,
    required DateTime date,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      if (user == null) throw Exception('User not logged in.');

      final uuid = const Uuid().v4();
      final transaction = Transaction(
        id: uuid,
        userId: user.id,
        amount: amount,
        type: type,
        category: category,
        note: note,
        transactionDate: date,
        createdAt: DateTime.now(),
      );

      await ref.read(transactionRepositoryProvider).addTransaction(transaction);
      ref.invalidate(dashboardDataProvider);
    });
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    String? note,
    required DateTime date,
    required DateTime createdAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      if (user == null) throw Exception('User not logged in.');

      final transaction = Transaction(
        id: id,
        userId: user.id,
        amount: amount,
        type: type,
        category: category,
        note: note,
        transactionDate: date,
        createdAt: createdAt,
      );

      await ref.read(transactionRepositoryProvider).updateTransaction(transaction);
      ref.invalidate(dashboardDataProvider);
    });
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      ref.invalidate(dashboardDataProvider);
    });
  }
}
