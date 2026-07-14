import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import 'transaction_local_datasource.dart';

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  static const _boxName = 'transactions_box';

  Future<Box<Map>> _getBox() async {
    return await Hive.openBox<Map>(_boxName);
  }

  @override
  Future<void> cacheTransaction(TransactionModel transaction) async {
    final box = await _getBox();
    await box.put(transaction.id, transaction.toJson());
  }

  @override
  Future<void> updateCachedTransaction(TransactionModel transaction) async {
    await cacheTransaction(transaction);
  }

  @override
  Future<void> deleteCachedTransaction(String transactionId) async {
    final box = await _getBox();
    await box.delete(transactionId);
  }

  @override
  Future<TransactionModel?> getCachedTransactionById(String transactionId) async {
    final box = await _getBox();
    final data = box.get(transactionId);
    if (data == null) return null;
    return TransactionModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<TransactionModel>> getCachedTransactions(String userId) async {
    final box = await _getBox();
    return box.values
        .map((data) => TransactionModel.fromJson(Map<String, dynamic>.from(data)))
        .where((tx) => tx.userId == userId)
        .toList();
  }

  @override
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.clear();
  }
}
