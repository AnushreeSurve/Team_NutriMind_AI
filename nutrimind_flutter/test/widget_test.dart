// Basic widget test for NutriMind AI.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrimind_flutter/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NutriMindApp()));
    await tester.pump();
    // Verify app shows the splash screen initially
    expect(find.text('NutriMind AI'), findsOneWidget);
  });
}
