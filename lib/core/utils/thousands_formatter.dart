import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Dynamic input formatter that blocks all alphabets/symbols, leaving only digits,
/// and adds comma groupings as thousands separators.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Strip all non-digit characters
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final int value = int.parse(cleanText);
    final String formatted = NumberFormat('#,###').format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
