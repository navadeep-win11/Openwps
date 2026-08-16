import 'package:flutter_test/flutter_test.dart';
import 'package:openwps/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenWPSApp());
    expect(find.text('OpenWPS'), findsOneWidget); // Checks if app loads HomeScreen title
  });
}
