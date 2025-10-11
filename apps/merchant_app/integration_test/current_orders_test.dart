import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:merchant_app/main.dart' as app;

/// Integration test for merchant CurrentOrders
/// [TC-MER-E2E-001]
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Merchant CurrentOrders Integration', () {
    testWidgets('Login and view CurrentOrders page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email')), 'merchant@test.com');
      final loginButton = find.text('登入');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify CurrentOrders page
      expect(find.text('Current Orders'), findsOneWidget);
    });
  });
}


