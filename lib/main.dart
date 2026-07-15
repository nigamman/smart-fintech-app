import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'core/services/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('preferences');

  // Initialize HomeWidget Service
  await HomeWidgetService.initialize();

  runApp(
    const ProviderScope(
      child: FinTrackApp(),
    ),
  );
}