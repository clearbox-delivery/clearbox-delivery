import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant.freezed.dart';
part 'merchant.g.dart';

@freezed
class Merchant with _$Merchant {
  const factory Merchant({
    required String id,
    required String name,
    required String address,
    @JsonKey(name: 'google_maps_url') String? googleMapsUrl,
    
    /// H3 cell (res=10) for merchant location
    @JsonKey(name: 'h3_cell') required String h3Cell,
    
    /// Menu stored as JSONB (MVP approach)
    Map<String, dynamic>? menu,
    
    /// Default prep time in minutes
    @JsonKey(name: 'prep_time_minutes') int? prepTimeMinutes,
    
    /// Operating status
    @JsonKey(name: 'is_open') bool? isOpen,
    
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Merchant;

  factory Merchant.fromJson(Map<String, dynamic> json) => 
    _$MerchantFromJson(json);
}


