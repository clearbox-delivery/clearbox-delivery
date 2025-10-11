import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String sku,
    required String name,
    required int quantity,
    required double unitPrice,
    
    /// Volume level for capacity calculation (V1-V4)
    @JsonKey(name: 'volume_level') String? volumeLevel,
    
    /// Weight level for capacity calculation (W1-W4)
    @JsonKey(name: 'weight_level') String? weightLevel,
    
    /// Special instructions for this item
    String? notes,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => 
    _$OrderItemFromJson(json);
}


