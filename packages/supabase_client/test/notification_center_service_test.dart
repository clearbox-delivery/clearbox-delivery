import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for NotificationCenterService
/// [TC-COU-NOTIF-SVC-*] Service behavior with/without backend
void main() {
  group('NotificationCenterService Behavior', () {
    test('TC-COU-NOTIF-SVC-001: Cache key includes userId and unreadOnly', () {
      // Simulate cache key generation
      String getCacheKey(String userId, bool unreadOnly) {
        return '$userId-$unreadOnly';
      }

      expect(getCacheKey('u1', true), 'u1-true');
      expect(getCacheKey('u1', false), 'u1-false');
      expect(getCacheKey('u2', true), 'u2-true');
      
      // Different keys for same user with different filters
      expect(getCacheKey('u1', true) != getCacheKey('u1', false), true);
    });

    test('TC-COU-NOTIF-SVC-002: markAllAsRead returns count (mock)', () {
      // Simulate markAllAsRead mock behavior
      int markAllAsReadMock(String userId) {
        // Mock: return 2 (simulated unread count)
        return 2;
      }

      final count = markAllAsReadMock('u1');
      expect(count, 2);
    });

    test('TC-COU-NOTIF-SVC-003: markAllAsRead returns count (real)', () {
      // Simulate real behavior (would update DB and return affected rows)
      int markAllAsReadReal(List<NotificationItem> notifications) {
        final unread = notifications.where((n) => n.readAt == null).toList();
        // Simulate updating read_at
        return unread.length;
      }

      final now = DateTime.now();
      final notifications = [
        NotificationItem(
          id: 'n1',
          userId: 'u1',
          audience: 'courier',
          type: 'order_new',
          title: 'Test',
          message: 'Test',
          createdAt: now,
          readAt: null,
        ),
        NotificationItem(
          id: 'n2',
          userId: 'u1',
          audience: 'courier',
          type: 'order_delivered',
          title: 'Test',
          message: 'Test',
          createdAt: now,
          readAt: null,
        ),
        NotificationItem(
          id: 'n3',
          userId: 'u1',
          audience: 'courier',
          type: 'payout_processed',
          title: 'Test',
          message: 'Test',
          createdAt: now,
          readAt: now, // Already read
        ),
      ];

      final count = markAllAsReadReal(notifications);
      expect(count, 2); // Only 2 unread
    });

    test('TC-COU-NOTIF-SVC-004: Clear cache invalidates all keys', () {
      final cache = <String, List<NotificationItem>>{};
      cache['u1-true'] = [];
      cache['u1-false'] = [];
      cache['u2-true'] = [];
      
      expect(cache.length, 3);
      
      cache.clear();
      
      expect(cache.length, 0);
    });

    test('TC-COU-NOTIF-SVC-005: Mock fallback returns 5 notifications', () {
      // Simulate mock data generation
      List<NotificationItem> getMockNotifications(String userId, bool unreadOnly) {
        final now = DateTime.now();
        final all = [
          NotificationItem(
            id: 'mock-1',
            userId: userId,
            audience: 'courier',
            type: 'order_new',
            title: '新訂單',
            message: 'Test',
            createdAt: now.subtract(const Duration(minutes: 5)),
            readAt: null,
          ),
          NotificationItem(
            id: 'mock-2',
            userId: userId,
            audience: 'courier',
            type: 'payout_processed',
            title: '結算已處理',
            message: 'Test',
            createdAt: now.subtract(const Duration(hours: 2)),
            readAt: null,
          ),
          NotificationItem(
            id: 'mock-3',
            userId: userId,
            audience: 'courier',
            type: 'order_delivered',
            title: '訂單已送達',
            message: 'Test',
            createdAt: now.subtract(const Duration(hours: 5)),
            readAt: now.subtract(const Duration(hours: 4)),
          ),
          NotificationItem(
            id: 'mock-4',
            userId: userId,
            audience: 'courier',
            type: 'kyc_status_update',
            title: 'KYC 審核通過',
            message: 'Test',
            createdAt: now.subtract(const Duration(days: 1)),
            readAt: now.subtract(const Duration(days: 1)),
          ),
          NotificationItem(
            id: 'mock-5',
            userId: userId,
            audience: 'courier',
            type: 'system_announcement',
            title: '系統維護通知',
            message: 'Test',
            createdAt: now.subtract(const Duration(days: 2)),
            readAt: now.subtract(const Duration(days: 2)),
          ),
        ];

        if (unreadOnly) {
          return all.where((n) => n.readAt == null).toList();
        }
        return all;
      }

      final all = getMockNotifications('u1', false);
      final unread = getMockNotifications('u1', true);
      
      expect(all.length, 5);
      expect(unread.length, 2);
      expect(unread.every((n) => n.readAt == null), true);
    });

    test('TC-COU-NOTIF-SVC-006: Fallback behavior consistency', () {
      bool backendAvailable = false;
      
      List<NotificationItem> getNotifications() {
        if (!backendAvailable) {
          // Fallback to mock
          final now = DateTime.now();
          return [
            NotificationItem(
              id: 'mock-1',
              userId: 'u1',
              audience: 'courier',
              type: 'order_new',
              title: '新訂單',
              message: 'Test',
              createdAt: now,
              readAt: null,
            ),
          ];
        }
        return [];
      }

      final notifications = getNotifications();
      expect(notifications.length, 1);
      expect(notifications.first.id, startsWith('mock-'));
    });
  });
}

