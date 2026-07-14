import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  TransactionModel _toModel(Transaction t) {
    return TransactionModel(
      id: t.id,
      userId: t.userId,
      amount: t.amount,
      type: t.type,
      category: t.category,
      note: t.note,
      transactionDate: t.transactionDate,
      createdAt: t.createdAt,
    );
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final model = _toModel(transaction);
    await remoteDataSource.addTransaction(model);
    await localDataSource.cacheTransaction(model);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final model = _toModel(transaction);
    await remoteDataSource.updateTransaction(model);
    await localDataSource.updateCachedTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await remoteDataSource.deleteTransaction(transactionId);
    await localDataSource.deleteCachedTransaction(transactionId);
  }

  @override
  Future<Transaction?> getTransactionById(String transactionId) async {
    final cached = await localDataSource.getCachedTransactionById(transactionId);
    if (cached != null) return cached;

    final remote = await remoteDataSource.getTransactionById(transactionId);
    if (remote != null) {
      await localDataSource.cacheTransaction(remote);
    }
    return remote;
  }

  @override
  Stream<List<Transaction>> getTransactions(String userId) {
    return remoteDataSource.getTransactions(userId).map((models) {
      for (final model in models) {
        localDataSource.cacheTransaction(model);
      }
      return models;
    });
  }
}