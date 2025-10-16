import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

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
    required String merchantId,
    required String category,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    String? volumeLevel,
    String? weightLevel,
    int? prepTimeMinutes,
    int? stockQuantity,
  }) async {
    // TODO: Backend RPC not yet available, use REST insert
    // Once backend ready, switch to RPC for better validation
    final response = await _client.from('menu_items').insert({
      'merchant_id': merchantId,
      'category': category,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'volume_level': volumeLevel,
      'weight_level': weightLevel,
      'prep_time_minutes': prepTimeMinutes ?? 15,
      'stock_quantity': stockQuantity ?? 50,
      'is_available': true,
    }).select().single();

    return MenuItem.fromJson(response as Map<String, dynamic>);
  }

  /// 更新菜单项
  Future<MenuItem> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    String? volumeLevel,
    String? weightLevel,
    int? prepTimeMinutes,
    int? stockQuantity,
  }) async {
    // TODO: Backend RPC not yet available, use REST update
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (isAvailable != null) updates['is_available'] = isAvailable;
    if (volumeLevel != null) updates['volume_level'] = volumeLevel;
    if (weightLevel != null) updates['weight_level'] = weightLevel;
    if (prepTimeMinutes != null) updates['prep_time_minutes'] = prepTimeMinutes;
    if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;

    final response = await _client
        .from('menu_items')
        .update(updates)
        .eq('id', itemId)
        .select()
        .single();

    return MenuItem.fromJson(response as Map<String, dynamic>);
  }

  /// 删除菜单项
  Future<void> deleteMenuItem(String itemId) async {
    // TODO: Backend RPC not yet available, use REST delete
    await _client.from('menu_items').delete().eq('id', itemId);
  }

  /// 按分类获取菜单（包含所有状态，由前端过滤）
  Future<Map<String, List<MenuItem>>> getMenuByCategory(
    String merchantId,
  ) async {
    // Fetch all items (not just available) for management
    final response = await _client
        .from('menu_items')
        .select()
        .eq('merchant_id', merchantId)
        .order('category')
        .order('name');

    final items = (response as List)
        .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
        .toList();

    final Map<String, List<MenuItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }

    return grouped;
  }

  /// 获取类别列表（按名称分组统计）
  Future<List<Map<String, dynamic>>> getCategories(String merchantId) async {
    final menuMap = await getMenuByCategory(merchantId);
    return menuMap.entries.map((entry) {
      return {
        'id': entry.key, // Use category name as ID for now
        'name': entry.key,
        'itemCount': entry.value.length,
        'isVisible': true, // TODO: Track category visibility in backend
      };
    }).toList();
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

// OTP Service 已獨立於 src/otp_service.dart，請由 supabase_client.dart 匯入使用

final locationServiceProvider = Provider<LocationService>((ref) {
  final client = ref.watch(supabaseProvider);
  return LocationService(client);
});

