import 'package:freezed_annotation/freezed_annotation.dart';

part 'courier_settings.freezed.dart';
part 'courier_settings.g.dart';

/// Courier account settings
/// [REQ-COU-ACC-002] Account settings management
@freezed
class CourierSettings with _$CourierSettings {
  const factory CourierSettings({
    required String courierId,
    @Default(true) bool isAcceptingOrders,
    @Default(true) bool pushEnabled,
    String? displayName,
    String? vehiclePlate,
    String? email,
  }) = _CourierSettings;

  factory CourierSettings.fromJson(Map<String, dynamic> json) =>
      _$CourierSettingsFromJson(json);
}

