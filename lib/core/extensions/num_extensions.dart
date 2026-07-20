import 'package:intl/intl.dart';

extension NumFormatter on num {
  String toCommaFormat() {
    return NumberFormat('#,##0', 'en_US').format(this);
  }
}
