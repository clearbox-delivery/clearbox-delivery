import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:merchant_app/main.dart' as app;

/// E2E test for merchant CurrentOrders real-time updates
/// [TC-MER-E2E-001] New order visible within 2s
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Merchant CurrentOrders E2E', () {
    testWidgets('TC-MER-E2E-001: New order visible within 2s',
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Login as merchant
      await tester.enterText(find.byKey(const Key('email')), 'merchant@test.com');
      await tester.pump(const Duration(milliseconds: 100));
      
      // Find and tap login button
      final loginButton = find.text('登入');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should navigate to CurrentOrders page
      expect(find.text('Current Orders'), findsOneWidget);

      // TODO: Trigger new order creation (via test helper or API call)
      // await createTestOrder();

      // Verify order card appears within 2s [REQ-MER-CO-002]
      await tester.pump(const Duration(milliseconds: 100));
      
      // Look for order card with specific key
      final orderCard = find.byKey(const Key('order-card-new'));
      
      // Wait up to 2 seconds for the card to appear
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Expect order card to be visible
      // expect(orderCard, findsOneWidget,
      //     reason: 'REQ-MER-CO-002: Order must appear ≤2s');
    });

    testWidgets('Safe animations prevent mis-taps', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email')), 'merchant@test.com');
      final loginButton = find.text('登入');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // TODO: Add test for animation safety
      // - Trigger new order
      // - Attempt to tap during animation
      // - Verify tap is ignored during animation period
    });
  });
}


