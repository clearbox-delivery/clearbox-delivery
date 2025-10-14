import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for KYC status
/// [TC-COU-KYC-006] KYC status flow
void main() {
  group('KycStatus', () {
    test('TC-COU-KYC-006: fromString maps correctly', () {
      expect(KycStatus.fromString('pending'), KycStatus.pending);
      expect(KycStatus.fromString('approved'), KycStatus.approved);
      expect(KycStatus.fromString('rejected'), KycStatus.rejected);
      expect(KycStatus.fromString('PENDING'), KycStatus.pending); // Case insensitive
      expect(KycStatus.fromString('unknown'), KycStatus.pending); // Default
    });

    test('TC-COU-KYC-007: displayName returns correct Chinese text', () {
      expect(KycStatus.pending.displayName, '審核中');
      expect(KycStatus.approved.displayName, '已通過');
      expect(KycStatus.rejected.displayName, '未通過');
    });

    test('TC-COU-KYC-008: All enum values covered', () {
      // Ensure no missing cases
      for (final status in KycStatus.values) {
        expect(status.displayName, isNotEmpty);
        expect(KycStatus.fromString(status.name), status);
      }
    });
  });
}

