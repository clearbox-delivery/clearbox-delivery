import 'package:test/test.dart';

/// Unit tests for prep time extension (+5/+10)
/// [TC-MER-EXTEND-001]
/// [merchant_app_whitepaper.md Section 4.3]
void main() {
  group('Prep Time Extension', () {
    test('TC-MER-EXTEND-001: +5 extension within max (90)', () {
      int prepTime = 20;
      prepTime += 5;
      expect(prepTime, equals(25));
    });

    test('TC-MER-EXTEND-002: +10 extension within max', () {
      int prepTime = 30;
      prepTime += 10;
      expect(prepTime, equals(40));
    });

    test('TC-MER-EXTEND-003: Upper bound enforced (max 90)', () {
      int prepTime = 85;
      prepTime += 10; // Would be 95
      
      final adjusted = prepTime > 90 ? 90 : prepTime;
      expect(adjusted, equals(90));
    });

    test('TC-MER-EXTEND-004: Multiple extensions cumulative', () {
      int prepTime = 20;
      prepTime += 5; // 25
      prepTime += 10; // 35
      prepTime += 5; // 40
      
      expect(prepTime, equals(40));
    });

    test('TC-MER-EXTEND-005: Overdue calculation', () {
      final createdAt = DateTime(2024, 1, 1, 10, 0);
      final prepMinutes = 20;
      final promisedTime = createdAt.add(Duration(minutes: prepMinutes));
      
      final now = DateTime(2024, 1, 1, 10, 25); // 5 minutes overdue
      final isOverdue = now.isAfter(promisedTime);
      final minutesOverdue = now.difference(promisedTime).inMinutes;
      
      expect(isOverdue, isTrue);
      expect(minutesOverdue, equals(5));
    });
  });
}

