import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_data/src/enums/actor_type.dart';
import 'package:core_data/src/enums/event_type.dart';
import 'package:core_data/src/enums/order_status.dart';

part 'order_event.freezed.dart';
part 'order_event.g.dart';

/// Order event for audit trail
/// [REQ-CORE-AUDIT-001] All state transitions must be recorded
@freezed
class OrderEvent with _$OrderEvent {
  const factory OrderEvent({
    required int id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'actor_id') String? actorId,
    @JsonKey(name: 'actor_type') required ActorType actorType,
    @JsonKey(name: 'from_status') OrderStatus? fromStatus,
    @JsonKey(name: 'to_status') required OrderStatus toStatus,
    @JsonKey(name: 'event_type') required EventType eventType,
    
    /// Additional metadata (prep_time, cancel_reason, etc.)
    Map<String, dynamic>? metadata,
    
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _OrderEvent;

  factory OrderEvent.fromJson(Map<String, dynamic> json) => 
    _$OrderEventFromJson(json);
}


