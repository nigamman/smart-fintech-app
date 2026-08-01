import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_helper.dart';

final notificationHelperProvider = Provider<NotificationHelper>((ref) {
  return NotificationHelper();
});
