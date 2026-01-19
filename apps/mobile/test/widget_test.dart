import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('MeshLink app starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MeshLinkApp());

    // Verify that splash screen shows MeshLink title
    expect(find.text('MeshLink'), findsAtLeastNWidgets(1));

    // Pump for async operations to complete (splash screen delay)
    await tester.pump(const Duration(seconds: 2));
  });
}
