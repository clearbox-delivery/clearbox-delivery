import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Address Service
/// [customer_app_whitepaper.md Section 2]
class AddressService {
  final SupabaseClient _client;

  AddressService(this._client);

  /// Get all addresses for current user
  Future<List<UserAddress>> getUserAddresses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserAddress.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new address
  Future<UserAddress> createAddress({
    required String name,
    required String address,
    required String googleMapsLink,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _client
        .from('user_addresses')
        .insert({
          'user_id': userId,
          'name': name,
          'address': address,
          'google_maps_link': googleMapsLink,
        })
        .select()
        .single();

    return UserAddress.fromJson(response as Map<String, dynamic>);
  }

  /// Update an address
  Future<UserAddress> updateAddress({
    required String id,
    required String name,
    required String address,
    required String googleMapsLink,
  }) async {
    final response = await _client
        .from('user_addresses')
        .update({
          'name': name,
          'address': address,
          'google_maps_link': googleMapsLink,
        })
        .eq('id', id)
        .select()
        .single();

    return UserAddress.fromJson(response as Map<String, dynamic>);
  }

  /// Delete an address
  Future<void> deleteAddress(String id) async {
    await _client.from('user_addresses').delete().eq('id', id);
  }
}

/// Address service provider
final addressServiceProvider = Provider<AddressService>((ref) {
  final client = ref.watch(supabaseProvider);
  return AddressService(client);
});

