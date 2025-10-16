import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// KYC service for document management and status tracking
/// [REQ-COU-KYC-003] Backend integration
class KycService {
  final SupabaseClient _client;

  KycService(this._client);

  /// Get courier's KYC status
  /// Returns null if courier not found or error
  Future<KycStatus?> getKycStatus(String courierId) async {
    try {
      final response = await _client
          .from('couriers')
          .select('kyc_status')
          .eq('id', courierId)
          .maybeSingle();

      if (response == null) return null;

      final statusString = response['kyc_status'] as String?;
      if (statusString == null) return KycStatus.pending;

      return KycStatus.fromString(statusString);
    } catch (e) {
      return null;
    }
  }

  /// List all KYC documents for a courier
  Future<List<KycDocument>> listKycDocuments(String courierId) async {
    try {
      final response = await _client
          .from('kyc_documents')
          .select()
          .eq('courier_id', courierId)
          .order('uploaded_at', ascending: false);

      return (response as List)
          .map((json) => KycDocument.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create KYC document record after successful upload
  /// [TC-COU-KYC-006] Record document upload
  Future<KycDocument?> createKycDocument({
    required String courierId,
    required String documentType,
    required String storageUrl,
  }) async {
    try {
      final response = await _client
          .from('kyc_documents')
          .insert({
            'courier_id': courierId,
            'document_type': documentType,
            'storage_url': storageUrl,
            'uploaded_at': DateTime.now().toIso8601String(),
            'status': 'pending',
          })
          .select()
          .single();

      return KycDocument.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Admin: Update KYC status
  /// [REQ-COU-KYC-004] Admin approval/rejection (not exposed to courier app)
  /// This method is for future admin dashboard use
  Future<void> adminUpdateKycStatus({
    required String courierId,
    required KycStatus status,
    String? reviewerNotes,
  }) async {
    await _client.from('couriers').update({
      'kyc_status': status.name,
      'kyc_reviewed_at': DateTime.now().toIso8601String(),
      'kyc_reviewer_notes': reviewerNotes,
    }).eq('id', courierId);
  }

  /// Mark KYC as submitted (courier completes all uploads)
  Future<void> markKycSubmitted(String courierId) async {
    await _client.from('couriers').update({
      'kyc_submitted_at': DateTime.now().toIso8601String(),
    }).eq('id', courierId);
  }
}

/// KYC service provider
final kycServiceProvider = Provider<KycService>((ref) {
  final client = ref.watch(supabaseProvider);
  return KycService(client);
});

