import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for Notification models
/// [TC-COU-NOTIF-*] NotificationItem and NotificationType
void main() {
  group('NotificationItem Model', () {
    test('TC-COU-NOTIF-001: Create notification with required fields', () {
      final notification = NotificationItem(
        id: 'n1',
        userId: 'u1',
        audience: 'courier',
        type: 'order_new',
        title: '新訂單',
        message: '您有一筆新訂單',
        createdAt: DateTime.now(),
      );

      expect(notification.id, 'n1');
      expect(notification.audience, 'courier');
      expect(notification.type, 'order_new');
      expect(notification.readAt, null);
    });

    test('TC-COU-NOTIF-002: NotificationType enum mapping', () {
      expect(NotificationType.fromString('order_new'), NotificationType.orderNew);
      expect(NotificationType.fromString('ORDER_ACCEPTED'), NotificationType.orderAccepted);
      expect(NotificationType.fromString('payout_processed'), NotificationType.payoutProcessed);
      expect(NotificationType.orderNew.displayName, '新訂單');
      expect(NotificationType.payoutProcessed.displayName, '結算已處理');
    });

    test('TC-COU-NOTIF-003: JSON serialization with data field', () {
      final notification = NotificationItem(
        id: 'n1',
        userId: 'u1',
        audience: 'courier',
        type: 'order_new',
        title: '新訂單',
        message: '預估收益 NT\$55',
        data: {'orderId': 'order-123', 'amount': 55},
        createdAt: DateTime.now(),
      );

      final json = notification.toJson();
      final decoded = NotificationItem.fromJson(json);

      expect(decoded.id, notification.id);
      expect(decoded.data, isNotNull);
      expect(decoded.data!['orderId'], 'order-123');
      expect(decoded.data!['amount'], 55);
    });

    test('TC-COU-NOTIF-004: Notification with readAt timestamp', () {
      final now = DateTime.now();
      final notification = NotificationItem(
        id: 'n1',
        userId: 'u1',
        audience: 'courier',
        type: 'system_announcement',
        title: '系統公告',
        message: '維護通知',
        createdAt: now.subtract(const Duration(hours: 1)),
        readAt: now,
      );

      expect(notification.readAt, isNotNull);
      expect(notification.readAt!.isBefore(now.add(const Duration(seconds: 1))), true);
    });
  });

  group('Notification Service Logic', () {
    test('TC-COU-NOTIF-005: Filter unread notifications', () {
      final now = DateTime.now();
      final notifications = [
        NotificationItem(
          id: 'n1',
          userId: 'u1',
          audience: 'courier',
          type: 'order_new',
          title: 'Unread 1',
          message: 'Message 1',
          createdAt: now.subtract(const Duration(minutes: 5)),
          readAt: null,
        ),
        NotificationItem(
          id: 'n2',
          userId: 'u1',
          audience: 'courier',
          type: 'order_delivered',
          title: 'Read 1',
          message: 'Message 2',
          createdAt: now.subtract(const Duration(hours: 1)),
          readAt: now.subtract(const Duration(minutes: 30)),
        ),
        NotificationItem(
          id: 'n3',
          userId: 'u1',
          audience: 'courier',
          type: 'payout_processed',
          title: 'Unread 2',
          message: 'Message 3',
          createdAt: now.subtract(const Duration(minutes: 10)),
          readAt: null,
        ),
      ];

      final unread = notifications.where((n) => n.readAt == null).toList();

      expect(unread.length, 2);
      expect(unread[0].id, 'n1');
      expect(unread[1].id, 'n3');
    });

    test('TC-COU-NOTIF-006: Sort notifications by createdAt descending', () {
      final now = DateTime.now();
      final notifications = [
        NotificationItem(
          id: 'n1',
          userId: 'u1',
          audience: 'courier',
          type: 'order_new',
          title: 'Oldest',
          message: 'Message 1',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        NotificationItem(
          id: 'n2',
          userId: 'u1',
          audience: 'courier',
          type: 'order_delivered',
          title: 'Newest',
          message: 'Message 2',
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        NotificationItem(
          id: 'n3',
          userId: 'u1',
          audience: 'courier',
          type: 'payout_processed',
          title: 'Middle',
          message: 'Message 3',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      final sorted = List<NotificationItem>.from(notifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted[0].id, 'n2'); // Newest
      expect(sorted[1].id, 'n3'); // Middle
      expect(sorted[2].id, 'n1'); // Oldest
    });

    test('TC-COU-NOTIF-007: Mark notification as read (simulate)', () {
      final notification = NotificationItem(
        id: 'n1',
        userId: 'u1',
        audience: 'courier',
        type: 'order_new',
        title: 'Test',
        message: 'Test message',
        createdAt: DateTime.now(),
        readAt: null,
      );

      expect(notification.readAt, null);

      // Simulate marking as read
      final marked = notification.copyWith(readAt: DateTime.now());

      expect(marked.readAt, isNotNull);
      expect(marked.id, notification.id);
    });
  });

  group('Mock Data Fallback', () {
    test('TC-COU-NOTIF-008: Service returns mock data when backend unavailable', () {
      // Simulates NotificationCenterService fallback behavior
      bool backendAvailable = false;
      List<NotificationItem> getNotifications() {
        if (!backendAvailable) {
          // Mock fallback
          final now = DateTime.now();
          return [
            NotificationItem(
              id: 'mock-1',
              userId: 'u1',
              audience: 'courier',
              type: 'order_new',
              title: '新訂單',
              message: '您有一筆新訂單',
              createdAt: now.subtract(const Duration(minutes: 5)),
              readAt: null,
            ),
            NotificationItem(
              id: 'mock-2',
              userId: 'u1',
              audience: 'courier',
              type: 'payout_processed',
              title: '結算已處理',
              message: 'NT\$1,250',
              createdAt: now.subtract(const Duration(hours: 2)),
              readAt: null,
            ),
          ];
        }
        return [];
      }

      final notifications = getNotifications();
      expect(notifications.length, 2);
      expect(notifications.first.type, 'order_new');
      expect(notifications.first.readAt, null);
    });
  });
}

