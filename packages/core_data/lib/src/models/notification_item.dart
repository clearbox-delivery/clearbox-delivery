import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

/// Notification item for user notifications
/// [REQ-COU-NOTIF-001] Track and display notifications
@freezed
class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required String id,
    required String userId,
    required String audience, // 'courier' | 'merchant' | 'customer'
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}

/// Notification type enum
enum NotificationType {
  orderNew,
  orderAccepted,
  orderPrepReady,
  orderPickedUp,
  orderDelivered,
  orderCancelled,
  orderArriving,
  systemAnnouncement,
  payoutProcessed,
  kycStatusUpdate;

  String get displayName {
    switch (this) {
      case NotificationType.orderNew:
        return '新訂單';
      case NotificationType.orderAccepted:
        return '訂單已接單';
      case NotificationType.orderPrepReady:
        return '餐點已備妥';
      case NotificationType.orderPickedUp:
        return '訂單已取餐';
      case NotificationType.orderDelivered:
        return '訂單已送達';
      case NotificationType.orderCancelled:
        return '訂單已取消';
      case NotificationType.orderArriving:
        return '外送員即將抵達';
      case NotificationType.systemAnnouncement:
        return '系統公告';
      case NotificationType.payoutProcessed:
        return '結算已處理';
      case NotificationType.kycStatusUpdate:
        return 'KYC 狀態更新';
    }
  }

  static NotificationType fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '')) {
      case 'ordernew':
        return NotificationType.orderNew;
      case 'orderaccepted':
        return NotificationType.orderAccepted;
      case 'orderprepready':
        return NotificationType.orderPrepReady;
      case 'orderpickedup':
        return NotificationType.orderPickedUp;
      case 'orderdelivered':
        return NotificationType.orderDelivered;
      case 'ordercancelled':
        return NotificationType.orderCancelled;
      case 'orderarriving':
        return NotificationType.orderArriving;
      case 'systemannouncement':
        return NotificationType.systemAnnouncement;
      case 'payoutprocessed':
        return NotificationType.payoutProcessed;
      case 'kycstatusupdate':
        return NotificationType.kycStatusUpdate;
      default:
        return NotificationType.systemAnnouncement;
    }
  }
}

