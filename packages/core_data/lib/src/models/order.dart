import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_data/src/enums/order_status.dart';
import 'package:core_data/src/models/order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Order model
/// [REQ-CUST-ORDER-001] - Customer sets delivery price, immutable after creation
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String customerId,
    required String merchantId,
    String? courierId,
    required OrderStatus status,
    
    /// User-set delivery price - IMMUTABLE after order creation
    /// Min: 30, Max: 5000 [REQ-CUST-ORDER-001]
    @JsonKey(name: 'delivery_price_user_set') required double deliveryPriceUserSet,
    
    required List<OrderItem> items,
    
    /// H3 cell (res=10) for merchant location
    @JsonKey(name: 'h3_merchant') String? h3Merchant,
    
    /// H3 cell (res=10) for customer location
    @JsonKey(name: 'h3_customer') String? h3Customer,
    
    /// Merchant prep time in minutes (set during confirmation)
    @JsonKey(name: 'prep_time_minutes') int? prepTimeMinutes,
    
    /// Customer notes/special instructions
    @JsonKey(name: 'customer_notes') String? customerNotes,
    
    /// Merchant notes (allergies, packaging requirements)
    @JsonKey(name: 'merchant_notes') String? merchantNotes,
    
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}


