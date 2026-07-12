import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
  }
}