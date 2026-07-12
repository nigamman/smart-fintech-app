import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<void> cacheTransaction(TransactionModel transaction);

  Future<void> updateCachedTransaction(TransactionModel transaction);

  Future<void> deleteCachedTransaction(String transactionId);

  Future<TransactionModel?> getCachedTransactionById(
      String transactionId,
      );

  Future<List<TransactionModel>> getCachedTransactions(
      String userId,
      );

  Future<void> clearCache();
}