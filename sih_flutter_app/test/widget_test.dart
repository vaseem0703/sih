import 'package:flutter_test/flutter_test.dart';
import 'package:sih_flutter_app/app/app.dart';

void main() {
  testWidgets('SIH App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SihApp());
    expect(find.text('Hello! 👋'), findsOneWidget);
  });
}
