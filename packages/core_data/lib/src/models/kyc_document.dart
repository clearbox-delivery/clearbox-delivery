import 'package:freezed_annotation/freezed_annotation.dart';

part 'kyc_document.freezed.dart';
part 'kyc_document.g.dart';

/// KYC document record
/// [REQ-COU-KYC-003] Track uploaded KYC documents
@freezed
class KycDocument with _$KycDocument {
  const factory KycDocument({
    required String id,
    required String courierId,
    required String documentType,
    required String storageUrl,
    required DateTime uploadedAt,
    @Default('pending') String status,
    String? reviewerNotes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _KycDocument;

  factory KycDocument.fromJson(Map<String, dynamic> json) =>
      _$KycDocumentFromJson(json);
}

/// KYC status enum
enum KycStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case KycStatus.pending:
        return '審核中';
      case KycStatus.approved:
        return '已通過';
      case KycStatus.rejected:
        return '未通過';
    }
  }

  static KycStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      case 'pending':
      default:
        return KycStatus.pending;
    }
  }
}

