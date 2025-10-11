import 'package:freezed_annotation/freezed_annotation.dart';

part 'courier.freezed.dart';
part 'courier.g.dart';

@freezed
class Courier with _$Courier {
  const factory Courier({
    required String id,
    required String name,
    
    /// Current H3 cell (res=10) - updated in real-time
    @JsonKey(name: 'current_h3_cell') String? currentH3Cell,
    
    /// Online/offline status
    @JsonKey(name: 'is_online') required bool isOnline,
    
    /// Phone number (masked for privacy)
    @JsonKey(name: 'phone_number') String? phoneNumber,
    
    /// Rating (1.00-5.00)
    double? rating,
    
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Courier;

  factory Courier.fromJson(Map<String, dynamic> json) => 
    _$CourierFromJson(json);
}


