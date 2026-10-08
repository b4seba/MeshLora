import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_mesh/main.dart';

void main() {
  testWidgets('Alerta Mesh smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RadioMeshApp());

    // Verify splash screen appears
    expect(find.text('Alerta Mesh'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);

    // Allow animations to finish
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Unmount to trigger dispose and cancel active timers
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

