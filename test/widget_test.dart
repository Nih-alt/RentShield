import 'package:flutter_test/flutter_test.dart';
import 'package:rent_shield/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const RentShieldApp());
    await tester.pumpAndSettle();
    expect(find.text('Rent Shield'), findsWidgets);
  });
}
