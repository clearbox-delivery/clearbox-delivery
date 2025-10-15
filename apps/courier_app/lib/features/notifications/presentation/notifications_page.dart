import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:intl/intl.dart';

/// Notification Center Page
/// [REQ-COU-NOTIF-001] Display notifications with read/unread management
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItem>? _allNotifications;
  List<NotificationItem>? _unreadNotifications;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    final courierId = authService.currentUserId;

    if (courierId == null) {
      setState(() => _loading = false);
      return;
    }

    final notificationService = ref.read(notificationCenterServiceProvider);
    final all = await notificationService.listNotifications(
      userId: courierId,
      unreadOnly: false,
    );
    final unread = await notificationService.listNotifications(
      userId: courierId,
      unreadOnly: true,
    );

    if (mounted) {
      setState(() {
        _allNotifications = all;
        _unreadNotifications = unread;
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(List<String> ids) async {
    final notificationService = ref.read(notificationCenterServiceProvider);
    await notificationService.markAsRead(ids);
    await _loadData();
  }

  Future<void> _markAllAsRead() async {
    final authService = ref.read(authServiceProvider);
    final courierId = authService.currentUserId;

    if (courierId == null) return;

    final notificationService = ref.read(notificationCenterServiceProvider);
    await notificationService.markAllAsRead(courierId);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已標記所有通知為已讀')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('通知中心'),
        actions: [
          if (_unreadNotifications != null && _unreadNotifications!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: '全部標記為已讀',
              onPressed: _markAllAsRead,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: _unreadNotifications == null
                  ? '未讀'
                  : '未讀 (${_unreadNotifications!.length})',
            ),
            const Tab(text: '全部'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUnreadTab(),
                _buildAllTab(),
              ],
            ),
    );
  }

  Widget _buildUnreadTab() {
    if (_unreadNotifications == null || _unreadNotifications!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: DesignTokens.textMuted),
            SizedBox(height: DesignTokens.sp4),
            Text(
              '沒有未讀通知',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        itemCount: _unreadNotifications!.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp2),
        itemBuilder: (context, index) {
          final notification = _unreadNotifications![index];
          return _buildNotificationCard(notification, isUnread: true);
        },
      ),
    );
  }

  Widget _buildAllTab() {
    if (_allNotifications == null || _allNotifications!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: DesignTokens.textMuted),
            SizedBox(height: DesignTokens.sp4),
            Text(
              '暫無通知記錄',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        itemCount: _allNotifications!.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp2),
        itemBuilder: (context, index) {
          final notification = _allNotifications![index];
          return _buildNotificationCard(
            notification,
            isUnread: notification.readAt == null,
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, {required bool isUnread}) {
    final type = NotificationType.fromString(notification.type);
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Dismissible(
      key: Key('notif-${notification.id}'),
      direction: isUnread ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) {
        _markAsRead([notification.id]);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.sp4),
        decoration: BoxDecoration(
          color: DesignTokens.success,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      child: CBCard(
        child: InkWell(
          onTap: isUnread
              ? () => _markAsRead([notification.id])
              : null,
          onLongPress: isUnread
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('標記為已讀'),
                      content: const Text('將此通知標記為已讀？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _markAsRead([notification.id]);
                          },
                          child: const Text('確認'),
                        ),
                      ],
                    ),
                  );
                }
              : null,
          child: Container(
            decoration: isUnread
                ? BoxDecoration(
                    color: DesignTokens.brand.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  )
                : null,
            child: ListTile(
              leading: Stack(
                children: [
                  Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 32,
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: DesignTokens.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  color: DesignTokens.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DesignTokens.sp1),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.sp2),
                  Text(
                    dateFormat.format(notification.createdAt),
                    style: const TextStyle(
                      fontSize: DesignTokens.fsXs,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.sp3,
                vertical: DesignTokens.sp2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderNew:
        return Icons.delivery_dining;
      case NotificationType.orderAccepted:
        return Icons.check_circle_outline;
      case NotificationType.orderPrepReady:
        return Icons.restaurant;
      case NotificationType.orderPickedUp:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderDelivered:
        return Icons.verified;
      case NotificationType.orderCancelled:
        return Icons.cancel_outlined;
      case NotificationType.orderArriving:
        return Icons.near_me;
      case NotificationType.systemAnnouncement:
        return Icons.campaign;
      case NotificationType.payoutProcessed:
        return Icons.account_balance_wallet;
      case NotificationType.kycStatusUpdate:
        return Icons.badge;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderNew:
        return DesignTokens.brand;
      case NotificationType.orderAccepted:
      case NotificationType.orderDelivered:
      case NotificationType.payoutProcessed:
      case NotificationType.kycStatusUpdate:
        return DesignTokens.success;
      case NotificationType.orderCancelled:
        return DesignTokens.danger;
      case NotificationType.orderArriving:
        return DesignTokens.warning;
      default:
        return DesignTokens.textSecondary;
    }
  }
}

