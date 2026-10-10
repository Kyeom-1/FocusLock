import 'package:flutter_test/flutter_test.dart';
import 'package:focus_lock/app.dart';

void main() {
  testWidgets('FocusLock app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusLockApp());

    await tester.pumpAndSettle();

    expect(find.text('FocusLock'), findsOneWidget);
  });
}