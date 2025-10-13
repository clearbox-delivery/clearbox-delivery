import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

/// 菜单品项模型
/// [REQ-MER-MENU-001]
@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    @JsonKey(name: 'merchant_id') required String merchantId,
    required String category,
    required String name,
    String? description,
    required double price,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'volume_level') String? volumeLevel,
    @JsonKey(name: 'weight_level') String? weightLevel,
    @JsonKey(name: 'prep_time_minutes') int? prepTimeMinutes,
    @JsonKey(name: 'is_available') required bool isAvailable,
    @JsonKey(name: 'stock_quantity') int? stockQuantity,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
    _$MenuItemFromJson(json);
}

/// 用户配置模型
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String role,
    required String name,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_verified') required bool isVerified,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
    _$UserProfileFromJson(json);
}

/// H3 热度数据
/// [REQ-COU-HEAT-001]
@freezed
class H3Heat with _$H3Heat {
  const factory H3Heat({
    @JsonKey(name: 'h3_cell') required String h3Cell,
    @JsonKey(name: 'heat_score') required double heatScore,
  }) = _H3Heat;

  factory H3Heat.fromJson(Map<String, dynamic> json) =>
    _$H3HeatFromJson(json);
}

