import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<void> addTransaction(TransactionModel transaction);

  Future<void> updateTransaction(TransactionModel transaction);

  Future<void> deleteTransaction(String transactionId);

  Future<TransactionModel?> getTransactionById(String transactionId);

  Stream<List<TransactionModel>> getTransactions(String userId);
}