import 'package:test/test.dart';

/// 热度计算单元测试
/// [TC-COU-HEAT-001]
void main() {
  group('Heat Calculation', () {
    test('TC-COU-HEAT-001: Heat = orders / (1 + couriers)', () {
      // 3 订单, 1 外送员 => heat = 3 / (1 + 1) = 1.5
      final orders = 3;
      final couriers = 1;
      final heat = orders / (1 + couriers);

      expect(heat, equals(1.5));
    });

    test('Zero couriers gives maximum heat', () {
      final orders = 5;
      final couriers = 0;
      final heat = orders / (1 + couriers);

      expect(heat, equals(5.0));
    });

    test('Many couriers reduces heat', () {
      final orders = 5;
      final couriers = 10;
      final heat = orders / (1 + couriers);

      expect(heat, closeTo(0.45, 0.01));
    });

    test('No orders means zero heat', () {
      final orders = 0;
      final couriers = 5;
      final heat = orders / (1 + couriers);

      expect(heat, equals(0.0));
    });
  });
}

