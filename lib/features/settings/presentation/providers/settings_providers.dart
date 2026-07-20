import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class PreferencesState {
  final String currency;
  final String dateFormat;
  final ThemeMode themeMode;
  final bool isEncryptionEnabled;
  final String? syncPassphrase;

  const PreferencesState({
    required this.currency,
    required this.dateFormat,
    required this.themeMode,
    this.isEncryptionEnabled = false,
    this.syncPassphrase,
  });

  PreferencesState copyWith({
    String? currency,
    String? dateFormat,
    ThemeMode? themeMode,
    bool? isEncryptionEnabled,
    String? syncPassphrase,
  }) {
    return PreferencesState(
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      themeMode: themeMode ?? this.themeMode,
      isEncryptionEnabled: isEncryptionEnabled ?? this.isEncryptionEnabled,
      syncPassphrase: syncPassphrase ?? this.syncPassphrase,
    );
  }
}

class PreferencesNotifier extends Notifier<PreferencesState> {
  Box get _box => Hive.box('preferences');

  @override
  PreferencesState build() {
    
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final userId = user?.id;

    if (userId == null) {
      return const PreferencesState(
        currency: '₹',
        dateFormat: 'dd MMM yyyy',
        themeMode: ThemeMode.dark,
        isEncryptionEnabled: false,
        syncPassphrase: null,
      );
    }

    final currency = _box.get('${userId}_currency', defaultValue: '₹') as String;
    final dateFormat = _box.get('${userId}_dateFormat', defaultValue: 'dd MMM yyyy') as String;
    
    final themeIndex = _box.get('${userId}_themeMode', defaultValue: 0) as int;
    final themeMode = ThemeMode.values[themeIndex];

    final isEncryptionEnabled = _box.get('${userId}_isEncryptionEnabled', defaultValue: false) as bool;
    final syncPassphrase = _box.get('${userId}_syncPassphrase') as String?;

    return PreferencesState(
      currency: currency,
      dateFormat: dateFormat,
      themeMode: themeMode,
      isEncryptionEnabled: isEncryptionEnabled,
      syncPassphrase: syncPassphrase,
    );
  }

  void updateCurrency(String newCurrency) {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      _box.put('${userId}_currency', newCurrency);
    } else {
      _box.put('currency', newCurrency);
    }
    state = state.copyWith(currency: newCurrency);
  }

  void updateDateFormat(String newFormat) {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      _box.put('${userId}_dateFormat', newFormat);
    } else {
      _box.put('dateFormat', newFormat);
    }
    state = state.copyWith(dateFormat: newFormat);
  }

  void updateThemeMode(ThemeMode newTheme) {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      _box.put('${userId}_themeMode', newTheme.index);
    } else {
      _box.put('themeMode', newTheme.index);
    }
    state = state.copyWith(themeMode: newTheme);
  }

  Future<void> enableEncryption(String passphrase, String userId) async {
    final pinHash = sha256.convert(utf8.encode(passphrase)).toString();
    await _box.put('${userId}_isEncryptionEnabled', true);
    await _box.put('${userId}_syncPassphrase', passphrase);
    await _box.put('${userId}_syncPinHash', pinHash);
    
    // Fallback keys for backward compatibility
    await _box.put('isEncryptionEnabled', true);
    await _box.put('syncPassphrase', passphrase);
    await _box.put('syncPinHash', pinHash);

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

    await _box.put('${userId}_isEncryptionEnabled', false);
    await _box.delete('${userId}_syncPassphrase');
    await _box.delete('${userId}_syncPinHash');
    
    await _box.put('isEncryptionEnabled', false);
    await _box.delete('syncPassphrase');
    await _box.delete('syncPinHash');

    state = state.copyWith(
      isEncryptionEnabled: false,
      syncPassphrase: null,
    );
    
    ref.invalidate(transactionsStreamProvider);
  }

  void setPassphrase(String passphrase) {
    final userId = ref.read(authStateProvider).value?.id;
    final pinHash = sha256.convert(utf8.encode(passphrase)).toString();
    if (userId != null) {
      _box.put('${userId}_isEncryptionEnabled', true);
      _box.put('${userId}_syncPassphrase', passphrase);
      _box.put('${userId}_syncPinHash', pinHash);
    }
    _box.put('isEncryptionEnabled', true);
    _box.put('syncPassphrase', passphrase);
    _box.put('syncPinHash', pinHash);

    state = state.copyWith(
      isEncryptionEnabled: true,
      syncPassphrase: passphrase,
    );
    ref.invalidate(transactionsStreamProvider);
  }

  void clearUserPreferences() {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      _box.delete('${userId}_isEncryptionEnabled');
      _box.delete('${userId}_syncPassphrase');
      _box.delete('${userId}_syncPinHash');
    }
    _box.delete('isEncryptionEnabled');
    _box.delete('syncPassphrase');
    _box.delete('syncPinHash');

    state = state.copyWith(
      isEncryptionEnabled: false,
      syncPassphrase: null,
    );
  }

  void lockSession() {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      _box.delete('${userId}_syncPassphrase');
    }
    _box.delete('syncPassphrase');

    state = state.copyWith(
      syncPassphrase: null,
    );
  }

  bool verifyPin(String pin) {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return false;
    
    final storedHash = _box.get('${userId}_syncPinHash') as String?;
    if (storedHash != null) {
      final pinHash = sha256.convert(utf8.encode(pin)).toString();
      return pinHash == storedHash;
    }
    return false;
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, PreferencesState>(
  PreferencesNotifier.new,
);
