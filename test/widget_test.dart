import 'package:flutter_test/flutter_test.dart';
import 'package:radio_mesh/main.dart';

void main() {
  testWidgets('Radio-Mesh smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RadioMeshApp());

    // Verify splash screen appears
    expect(find.text('Radio-Mesh'), findsOneWidget);
    expect(find.text('COMENZAR'), findsOneWidget);
  });
}
