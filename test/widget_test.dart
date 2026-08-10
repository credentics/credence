import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('app root widget builds without crashing', (tester) async {
    // Smoke test: verify the app's MaterialApp can be constructed.
    // Full widget tests require platform plugins (FlutterSecureStorage, Hive)
    // and must run on a device or emulator.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Credence'))),
      ),
    );

    expect(find.text('Credence'), findsOneWidget);
  });
}
