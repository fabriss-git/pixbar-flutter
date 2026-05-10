import 'package:flutter_test/flutter_test.dart';
import 'package:pixbar_app/main.dart';

void main() {
  testWidgets('PixBar smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PixBarApp());
  });
}