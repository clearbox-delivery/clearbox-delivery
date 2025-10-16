import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/features/orders/presentation/confirm_order_dialog.dart';
import 'package:merchant_app/features/orders/presentation/cancel_order_dialog.dart';

/// Pending Confirm Tab
/// [merchant_app_whitepaper.md Section 4.1]
/// [REQ-MER-CO-001] Merchant confirms order manufacturability
class PendingConfirmTab extends ConsumerWidget {
  const PendingConfirmTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Center(child: Text('Please login'));
    }

    // Watch realtime orders with PENDING_CONFIRM status
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

        // Filter client-side for PENDING_STORE_CONFIRM
        final pendingOrders = allOrders
            .where((o) => o.status == OrderStatus.pendingStoreConfirm)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first

        if (pendingOrders.isEmpty) {
          return const CBEmptyState(
            icon: Icons.inbox_outlined,
            title: '暫無待確認訂單',
            description: '新訂單會出現在這裡',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          itemCount: pendingOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp4),
          itemBuilder: (context, index) {
            final order = pendingOrders[index];
            return _PendingConfirmCard(order: order);
          },
        );
      },
    );
  }
}

class _PendingConfirmCard extends ConsumerWidget {
  final Order order;

  const _PendingConfirmCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate capacity warning
    final hasCapacityWarning = _checkCapacityWarning(order);

    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '訂單 ${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsLg,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Text(
                _formatTime(order.createdAt),
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Customer name
          Text(
            '顧客: ${order.customerId.substring(0, 8)}', // TODO: Fetch customer nickname
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Items summary
          Text(
            '${order.items.length} 項餐點',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textPrimary,
            ),
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Pricing
          Row(
            children: [
              Text(
                '餐費 NT\$${_calculateMealPrice(order).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              Text(
                '外送費 NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          if (hasCapacityWarning) ...[
            const SizedBox(height: DesignTokens.sp3),
            Container(
              padding: const EdgeInsets.all(DesignTokens.sp2),
              decoration: BoxDecoration(
                color: DesignTokens.warn.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: DesignTokens.warn),
                  const SizedBox(width: DesignTokens.sp2),
                  const Expanded(
                    child: Text(
                      '可能超過外送員載運上限',
                      style: TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: DesignTokens.warn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (order.customerNotes?.isNotEmpty == true) ...[
            const SizedBox(height: DesignTokens.sp3),
            Text(
              '備註: ${order.customerNotes}',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: DesignTokens.sp4),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: CBButton(
                  text: '確認可接',
                  onPressed: () => _showConfirmDialog(context, ref, order),
                  size: CBButtonSize.medium,
                ),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: CBButton(
                  text: '無法接單',
                  onPressed: () => _showCancelDialog(context, ref, order),
                  type: CBButtonType.secondary,
                  size: CBButtonSize.medium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateMealPrice(Order order) {
    return order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
  }

  bool _checkCapacityWarning(Order order) {
    // Simple heuristic: if total items > 5, show warning
    // TODO: Use actual volume/weight calculation from menu_items
    final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    return totalItems > 5;
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showConfirmDialog(BuildContext context, WidgetRef ref, Order order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmOrderDialog(order: order),
    );

    if (result == true) {
      // Refresh handled by Realtime stream
    }
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref, Order order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CancelOrderDialog(order: order),
    );

    if (result == true) {
      // Refresh handled by Realtime stream
    }
  }
}

