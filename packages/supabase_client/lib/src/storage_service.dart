import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Storage service for file uploads
/// [REQ-COU-KYC-001] Upload KYC documents to Supabase Storage
class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  /// Upload KYC document
  /// [courier_app_whitepaper.md Section 2]
  /// [REQ-COU-KYC-002] Actual storage upload
  /// Bucket: kyc-documents/{courierId}/{documentType}.jpg
  Future<String?> uploadKYCDocument({
    required String courierId,
    required String documentType,
    required List<int> fileBytes,
    String fileExtension = 'jpg',
  }) async {
    try {
      final path = '$courierId/$documentType.$fileExtension';

      // Upload to Supabase Storage
      await _client.storage
          .from('kyc-documents')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExtension',
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from('kyc-documents')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      // Storage bucket not created or upload failed
      // Return null to trigger error handling in UI
      return null;
    }
  }

  /// Upload order photo (arrival at merchant, delivery to customer)
  /// Bucket: order-photos/{orderId}/{photoType}.jpg
  Future<String?> uploadOrderPhoto({
    required String orderId,
    required String photoType, // 'merchant_arrival', 'customer_delivery'
    required List<int> fileBytes,
  }) async {
    try {
      final path = '$orderId/$photoType.jpg';

      // TODO: Actual upload
      return 'https://mock-storage.supabase.co/order-photos/$path';
    } catch (e) {
      return null;
    }
  }

  /// Upload menu item photo
  /// Bucket: menu-photos/{merchantId}/{itemId}.jpg
  Future<String?> uploadMenuPhoto({
    required String merchantId,
    required String itemId,
    required List<int> fileBytes,
  }) async {
    try {
      final path = '$merchantId/$itemId.jpg';

      // TODO: Actual upload
      return 'https://mock-storage.supabase.co/menu-photos/$path';
    } catch (e) {
      return null;
    }
  }
}

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseProvider);
  return StorageService(client);
});

