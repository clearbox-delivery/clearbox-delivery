import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/features/orders/presentation/extend_prep_time_dialog.dart';
import 'package:merchant_app/features/orders/presentation/cancel_order_dialog.dart';

/// Preparing Tab (已接單，開始備餐)
/// [merchant_app_whitepaper.md Section 4.3]
/// [REQ-MER-CO-003] Merchant prepares order after courier acceptance
class PreparingTab extends ConsumerWidget {
  const PreparingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Center(child: Text('Please login'));
    }

    final ordersStream = ref.watch(realtimeServiceProvider).watchMerchantOrders(merchantId: merchantId);

    return StreamBuilder<List<Order>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CBLoadingIndicator());
        }

        if (snapshot.hasError) {
          return CBErrorState(
            title: '載入失敗',
            description: snapshot.error.toString(),
          );
        }

        final allOrders = snapshot.data ?? [];

        // Filter client-side for COURIER_ASSIGNED (preparing state)
        final preparingOrders = allOrders
            .where((o) => o.status == OrderStatus.courierAssigned)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (preparingOrders.isEmpty) {
          return const CBEmptyState(
            icon: Icons.restaurant_outlined,
            title: '暫無備餐訂單',
            description: '外送員接單後會進入備餐',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          itemCount: preparingOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp4),
          itemBuilder: (context, index) {
            final order = preparingOrders[index];
            return _PreparingCard(order: order);
          },
        );
      },
    );
  }
}

class _PreparingCard extends ConsumerWidget {
  final Order order;

  const _PreparingCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    // Calculate promised pickup time and check if overdue
    final promisedTime = _calculatePromisedTime(order);
    final isOverdue = DateTime.now().isAfter(promisedTime);
    final minutesOverdue = isOverdue
        ? DateTime.now().difference(promisedTime).inMinutes
        : 0;

    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID
          Text(
            '訂單 ${order.id.substring(0, 8)}',
            style: const TextStyle(
              fontSize: DesignTokens.fsLg,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Courier info (mock data for MVP)
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: DesignTokens.bgSubtle,
                child: Icon(Icons.person, size: 20, color: DesignTokens.textMuted),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '外送員${order.courierId?.substring(0, 6) ?? "未知"}',
                          style: const TextStyle(
                            fontSize: DesignTokens.fsMd,
                            fontWeight: FontWeight.w500,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.sp2),
                        const Icon(Icons.star, size: 14, color: DesignTokens.accent),
                        const Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: DesignTokens.fsSm,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.sp1),
                    const Text(
                      '近七日 32 單 • 機車',
                      style: TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // ETA and distance (mock)
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: DesignTokens.brand),
              const SizedBox(width: DesignTokens.sp2),
              const Text(
                '到店 ETA: 5 分鐘',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(Icons.location_on_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              const Text(
                '距離 1.2km',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Promised pickup time
          Text(
            '承諾取餐: ${_formatTime(promisedTime)}',
            style: TextStyle(
              fontSize: DesignTokens.fsSm,
              color: isOverdue ? DesignTokens.danger : DesignTokens.textSecondary,
              fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
            ),
          ),

          // Overdue indicator
          if (isOverdue) ...[
            const SizedBox(height: DesignTokens.sp3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.sp3,
                vertical: DesignTokens.sp2,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                border: Border.all(color: DesignTokens.danger, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: DesignTokens.danger),
                  const SizedBox(width: DesignTokens.sp2),
                  Text(
                    '已延誤 $minutesOverdue 分鐘',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: DesignTokens.sp4),

          // Action buttons row 1
          Row(
            children: [
              Expanded(
                child: CBButton(
                  text: '我備好囉',
                  onPressed: () => _handlePrepReady(context, ref),
                  size: CBButtonSize.medium,
                ),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: CBButton(
                  text: '需要更多時間',
                  onPressed: () => _showExtendDialog(context, ref),
                  type: CBButtonType.secondary,
                  size: CBButtonSize.medium,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Action buttons row 2
          Row(
            children: [
              Expanded(
                child: CBButton(
                  text: '聯絡外送員',
                  onPressed: () => _handleContact(context),
                  icon: Icons.phone_outlined,
                  type: CBButtonType.secondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: CBButton(
                  text: '特殊取消',
                  onPressed: () => _showCancelDialog(context, ref),
                  type: CBButtonType.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _calculatePromisedTime(Order order) {
    // Promised = created_at + prep_time_minutes
    // TODO: Should use actual accepted_at timestamp from events
    final prepMinutes = order.prepTimeMinutes ?? 15;
    return order.createdAt.add(Duration(minutes: prepMinutes));
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handlePrepReady(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認備好'),
        content: const Text('餐點已備好，通知外送員可到店取餐？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(orderServiceProvider).merchantPrepReady(
          orderId: order.id,
        );

        if (context.mounted) {
          CBToast.show(
            context: context,
            message: '已通知外送員可取餐',
            type: CBToastType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          CBToast.show(
            context: context,
            message: '操作失敗: $e',
            type: CBToastType.error,
          );
        }
      }
    }
  }

  Future<void> _showExtendDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => ExtendPrepTimeDialog(order: order),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => CancelOrderDialog(order: order),
    );
  }

  void _handleContact(BuildContext context) {
    // TODO: Implement masked phone/message
    CBToast.show(
      context: context,
      message: '聯絡功能開發中（雙向遮罩保護）',
      type: CBToastType.info,
    );
  }
}

