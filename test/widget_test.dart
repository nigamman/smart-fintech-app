import 'package:fintech_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame under ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(
        child: FumetApp(),
      ),
    );

    // Verify that the main app widget is built.
    expect(find.byType(FumetApp), findsOneWidget);
  });
}
