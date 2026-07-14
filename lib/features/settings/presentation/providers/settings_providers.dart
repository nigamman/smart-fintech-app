import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PreferencesState {
  final String currency;
  final String dateFormat;
  final ThemeMode themeMode;

  const PreferencesState({
    required this.currency,
    required this.dateFormat,
    required this.themeMode,
  });

  PreferencesState copyWith({
    String? currency,
    String? dateFormat,
    ThemeMode? themeMode,
  }) {
    return PreferencesState(
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      themeMode: themeMode ?? this.themeMode,
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

    return PreferencesState(
      currency: currency,
      dateFormat: dateFormat,
      themeMode: themeMode,
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
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, PreferencesState>(
  PreferencesNotifier.new,
);
