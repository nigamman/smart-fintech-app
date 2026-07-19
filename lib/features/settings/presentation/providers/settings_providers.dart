import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';

class PreferencesState {
  final String currency;
  final String dateFormat;
  final ThemeMode themeMode;
  final bool isEncryptionEnabled;
  final String? syncPassphrase;
  final String geminiApiKey;

  const PreferencesState({
    required this.currency,
    required this.dateFormat,
    required this.themeMode,
    this.isEncryptionEnabled = false,
    this.syncPassphrase,
    this.geminiApiKey = '',
  });

  PreferencesState copyWith({
    String? currency,
    String? dateFormat,
    ThemeMode? themeMode,
    bool? isEncryptionEnabled,
    String? syncPassphrase,
    String? geminiApiKey,
  }) {
    return PreferencesState(
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      themeMode: themeMode ?? this.themeMode,
      isEncryptionEnabled: isEncryptionEnabled ?? this.isEncryptionEnabled,
      syncPassphrase: syncPassphrase ?? this.syncPassphrase,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}

class PreferencesNotifier extends Notifier<PreferencesState> {
  late final Box _box;

  @override
  PreferencesState build() {
    _box = Hive.box('preferences');
    
    final currency = _box.get('currency', defaultValue: '₹') as String;
    final dateFormat = _box.get('dateFormat', defaultValue: 'dd MMM yyyy') as String;
    
    final themeIndex = _box.get('themeMode', defaultValue: 0) as int;
    final themeMode = ThemeMode.values[themeIndex];

    final isEncryptionEnabled = _box.get('isEncryptionEnabled', defaultValue: false) as bool;
    final syncPassphrase = _box.get('syncPassphrase') as String?;
    final geminiApiKey = _box.get('geminiApiKey', defaultValue: '') as String;

    return PreferencesState(
      currency: currency,
      dateFormat: dateFormat,
      themeMode: themeMode,
      isEncryptionEnabled: isEncryptionEnabled,
      syncPassphrase: syncPassphrase,
      geminiApiKey: geminiApiKey,
    );
  }

  void updateCurrency(String newCurrency) {
    _box.put('currency', newCurrency);
    state = state.copyWith(currency: newCurrency);
  }

  void updateDateFormat(String newFormat) {
    _box.put('dateFormat', newFormat);
    state = state.copyWith(dateFormat: newFormat);
  }

  void updateThemeMode(ThemeMode newTheme) {
    _box.put('themeMode', newTheme.index);
    state = state.copyWith(themeMode: newTheme);
  }

  void updateGeminiApiKey(String key) {
    _box.put('geminiApiKey', key);
    state = state.copyWith(geminiApiKey: key);
  }

  Future<void> enableEncryption(String passphrase, String userId) async {
    await _box.put('isEncryptionEnabled', true);
    await _box.put('syncPassphrase', passphrase);
    state = state.copyWith(
      isEncryptionEnabled: true,
      syncPassphrase: passphrase,
    );

    final localDataSource = ref.read(transactionLocalDataSourceProvider);
    final remoteDataSource = ref.read(transactionRemoteDataSourceProvider);
    
    final localTxs = await localDataSource.getCachedTransactions(userId);
    for (final tx in localTxs) {
      final encrypted = tx.encrypt(passphrase);
      await remoteDataSource.addTransaction(encrypted);
    }
    
    ref.invalidate(transactionsStreamProvider);
  }

  Future<void> disableEncryption(String userId) async {
    final localDataSource = ref.read(transactionLocalDataSourceProvider);
    final remoteDataSource = ref.read(transactionRemoteDataSourceProvider);
    
    final localTxs = await localDataSource.getCachedTransactions(userId);
    for (final tx in localTxs) {
      final plaintext = tx.copyWith(isEncrypted: false, encryptedData: null);
      await remoteDataSource.addTransaction(plaintext);
    }

    await _box.put('isEncryptionEnabled', false);
    await _box.delete('syncPassphrase');
    state = state.copyWith(
      isEncryptionEnabled: false,
      syncPassphrase: null,
    );
    
    ref.invalidate(transactionsStreamProvider);
  }

  void setPassphrase(String passphrase) {
    _box.put('isEncryptionEnabled', true);
    _box.put('syncPassphrase', passphrase);
    state = state.copyWith(
      isEncryptionEnabled: true,
      syncPassphrase: passphrase,
    );
    ref.invalidate(transactionsStreamProvider);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, PreferencesState>(
  PreferencesNotifier.new,
);
