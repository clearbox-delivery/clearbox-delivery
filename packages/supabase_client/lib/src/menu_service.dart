import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// 菜单服务
/// [REQ-MER-MENU-001]
class MenuService {
  final SupabaseClient _client;

  MenuService(this._client);

  /// 获取商家菜单
  Future<List<MenuItem>> getMerchantMenu(String merchantId) async {
    final response = await _client
        .from('menu_items')
        .select()
        .eq('merchant_id', merchantId)
        .eq('is_available', true)
        .order('category')
        .order('name');

    return (response as List)
        .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 创建菜单项
  Future<MenuItem> createMenuItem({
    required String category,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    String? volumeLevel,
    String? weightLevel,
    int prepTimeMinutes = 15,
  }) async {
    final response = await _client.rpc('create_menu_item', params: {
      'p_category': category,
      'p_name': name,
      'p_description': description,
      'p_price': price,
      'p_image_url': imageUrl,
      'p_volume_level': volumeLevel,
      'p_weight_level': weightLevel,
      'p_prep_time_minutes': prepTimeMinutes,
    });

    return MenuItem.fromJson(response as Map<String, dynamic>);
  }

  /// 更新菜单项
  Future<MenuItem> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
  }) async {
    final response = await _client.rpc('update_menu_item', params: {
      'p_item_id': itemId,
      'p_name': name,
      'p_description': description,
      'p_price': price,
      'p_is_available': isAvailable,
    });

    return MenuItem.fromJson(response as Map<String, dynamic>);
  }

  /// 删除菜单项
  Future<bool> deleteMenuItem(String itemId) async {
    final response = await _client.rpc('delete_menu_item', params: {
      'p_item_id': itemId,
    });

    return response as bool;
  }

  /// 按分类获取菜单
  Future<Map<String, List<MenuItem>>> getMenuByCategory(
    String merchantId,
  ) async {
    final items = await getMerchantMenu(merchantId);
    final Map<String, List<MenuItem>> grouped = {};

    for (final item in items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }

    return grouped;
  }
}

/// OTP 服务
/// [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002]
class OTPService {
  final SupabaseClient _client;

  OTPService(this._client);

  /// 发送 OTP
  Future<Map<String, dynamic>> sendOTP({
    required String identifier,
    required String otpType, // 'EMAIL' or 'PHONE'
    required String deviceId,
  }) async {
    final response = await _client.rpc('send_otp', params: {
      'p_identifier': identifier,
      'p_otp_type': otpType,
      'p_device_id': deviceId,
    });

    return response as Map<String, dynamic>;
  }

  /// 验证 OTP
  Future<bool> verifyOTP({
    required String identifier,
    required String otpCode,
    required String otpType,
    required String deviceId,
  }) async {
    try {
      final response = await _client.rpc('verify_otp', params: {
        'p_identifier': identifier,
        'p_otp_code': otpCode,
        'p_otp_type': otpType,
        'p_device_id': deviceId,
      });

      return (response as Map<String, dynamic>)['verified'] == true;
    } catch (e) {
      return false;
    }
  }
}

/// 位置服务
/// [REQ-COU-HEAT-001]
class LocationService {
  final SupabaseClient _client;

  LocationService(this._client);

  /// 更新外送员位置
  Future<void> updateCourierLocation({
    required String h3Cell,
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    await _client.rpc('update_courier_location', params: {
      'p_h3_cell': h3Cell,
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_is_online': isOnline,
    });
  }

  /// 获取 H3 热度数据
  Future<List<H3Heat>> getH3Heat(List<String> h3Cells) async {
    final response = await _client.rpc('calculate_h3_heat', params: {
      'p_h3_cells': h3Cells,
    });

    return (response as List)
        .map((json) => H3Heat.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

/// Providers
final menuServiceProvider = Provider<MenuService>((ref) {
  final client = ref.watch(supabaseProvider);
  return MenuService(client);
});

final otpServiceProvider = Provider<OTPService>((ref) {
  final client = ref.watch(supabaseProvider);
  return OTPService(client);
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final client = ref.watch(supabaseProvider);
  return LocationService(client);
});

