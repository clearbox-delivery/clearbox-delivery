import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_address.freezed.dart';
part 'user_address.g.dart';

/// User saved address
/// [customer_app_whitepaper.md Section 2]
@freezed
class UserAddress with _$UserAddress {
  const factory UserAddress({
    required String id,
    required String userId,
    required String name,
    required String address,
    required String googleMapsLink,
    required DateTime createdAt,
    @Default(25.0330) double latitude, // Taipei 101 default
    @Default(121.5654) double longitude,
  }) = _UserAddress;

  factory UserAddress.fromJson(Map<String, dynamic> json) =>
      _$UserAddressFromJson(json);
}

