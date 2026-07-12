import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<void> addTransaction(Transaction transaction);

  Future<void> updateTransaction(Transaction transaction);

  Future<void> deleteTransaction(String transactionId);

  Future<Transaction?> getTransactionById(String transactionId);

  Stream<List<Transaction>> getTransactions(String userId);
}