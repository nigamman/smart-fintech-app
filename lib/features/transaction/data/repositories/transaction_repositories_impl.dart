import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl
    implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<void> addTransaction(
      Transaction transaction,
      ) async {}

  @override
  Future<void> updateTransaction(
      Transaction transaction,
      ) async {}

  @override
  Future<void> deleteTransaction(
      String transactionId,
      ) async {}

  @override
  Future<Transaction?> getTransactionById(
      String transactionId,
      ) async {}

  @override
  Stream<List<Transaction>> getTransactions(
      String userId,
      ) {
    throw UnimplementedError();
  }
}