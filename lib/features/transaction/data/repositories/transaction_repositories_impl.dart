import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource localDataSource;
  final Ref ref;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.ref,
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
      isSplit: t.isSplit,
      splitWith: t.splitWith,
      splitPercentage: t.splitPercentage,
      isSplitPaid: t.isSplitPaid,
      isEncrypted: t.isEncrypted,
      encryptedData: t.encryptedData,
    );
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final model = _toModel(transaction);
    final preferences = ref.read(preferencesProvider);
    if (preferences.isEncryptionEnabled && preferences.syncPassphrase != null) {
      final encryptedModel = model.encrypt(preferences.syncPassphrase!);
      await remoteDataSource.addTransaction(encryptedModel);
    } else {
      await remoteDataSource.addTransaction(model);
    }
    await localDataSource.cacheTransaction(model);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final model = _toModel(transaction);
    final preferences = ref.read(preferencesProvider);
    if (preferences.isEncryptionEnabled && preferences.syncPassphrase != null) {
      final encryptedModel = model.encrypt(preferences.syncPassphrase!);
      await remoteDataSource.updateTransaction(encryptedModel);
    } else {
      await remoteDataSource.updateTransaction(model);
    }
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
      final preferences = ref.read(preferencesProvider);
      if (remote.isEncrypted) {
        if (preferences.isEncryptionEnabled && preferences.syncPassphrase != null) {
          try {
            final decrypted = remote.decrypt(preferences.syncPassphrase!);
            await localDataSource.cacheTransaction(decrypted);
            return decrypted;
          } catch (_) {
            return remote;
          }
        }
        return remote;
      }
      await localDataSource.cacheTransaction(remote);
    }
    return remote;
  }

  @override
  Stream<List<Transaction>> getTransactions(String userId) {
    return remoteDataSource.getTransactions(userId).asyncMap((models) async {
      final preferences = ref.read(preferencesProvider);
      final list = <Transaction>[];
      for (final model in models) {
        if (model.isEncrypted) {
          if (preferences.isEncryptionEnabled && preferences.syncPassphrase != null) {
            try {
              final decrypted = model.decrypt(preferences.syncPassphrase!);
              await localDataSource.cacheTransaction(decrypted);
              list.add(decrypted);
            } catch (_) {
              // Try falling back to local cache if we already decrypted/stored it previously
              final cached = await localDataSource.getCachedTransactionById(model.id);
              if (cached != null && !cached.isEncrypted) {
                list.add(cached);
              } else {
                list.add(model);
              }
            }
          } else {
            final cached = await localDataSource.getCachedTransactionById(model.id);
            if (cached != null && !cached.isEncrypted) {
              list.add(cached);
            } else {
              list.add(model);
            }
          }
        } else {
          await localDataSource.cacheTransaction(model);
          list.add(model);
        }
      }
      return list;
    });
  }
}