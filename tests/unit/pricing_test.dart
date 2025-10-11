import 'package:test/test.dart';
import 'package:domain/domain.dart';

/// Unit tests for price validation
/// [TC-CUST-001, TC-CUST-002]
void main() {
  group('PriceValidator', () {
    test('TC-CUST-001: Valid delivery price 30-5000', () {
      // Valid prices
      expect(PriceValidator.validate(30).isValid, isTrue);
      expect(PriceValidator.validate(45).isValid, isTrue);
      expect(PriceValidator.validate(100).isValid, isTrue);
      expect(PriceValidator.validate(5000).isValid, isTrue);
    });

    test('TC-CUST-002: Price below minimum returns error', () {
      final result = PriceValidator.validate(0);
      expect(result.isValid, isFalse);
      expect(result.errorCode, equals('ERR_PRICE_MIN'));
    });

    test('TC-CUST-002: Price above maximum returns error', () {
      final result = PriceValidator.validate(6000);
      expect(result.isValid, isFalse);
      expect(result.errorCode, equals('ERR_PRICE_MAX'));
    });

    test('Negative price returns error', () {
      final result = PriceValidator.validate(-10);
      expect(result.isValid, isFalse);
    });

    test('Boundary values', () {
      expect(PriceValidator.validate(29.99).isValid, isFalse);
      expect(PriceValidator.validate(30.00).isValid, isTrue);
      expect(PriceValidator.validate(5000.00).isValid, isTrue);
      expect(PriceValidator.validate(5000.01).isValid, isFalse);
    });
  });
}


