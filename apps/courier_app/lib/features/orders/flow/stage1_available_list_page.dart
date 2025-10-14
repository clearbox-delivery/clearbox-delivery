import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/features/orders/flow/stage2_go_merchant_page.dart';

/// Stage 1: Available Orders List with R/T sorting
/// [courier_app_whitepaper.md Section 4.2 進度1]
/// [REQ-COU-FLOW-001] Show WAITING_COURIER orders, sorted by R/T
class Stage1AvailableListPage extends ConsumerWidget {
  const Stage1AvailableListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final courierId = authService.currentUserId;

    if (courierId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    // Use Realtime stream for available orders
    final ordersStream = ref.watch(realtimeServiceProvider).watchAvailableOrders();

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('可接訂單'),
        subtitle: const Text(
          '依單位時間收益排序（R/T）',
          style: TextStyle(
            fontSize: DesignTokens.fsSm,
            color: DesignTokens.textSecondary,
          ),
        ),
      ),
      body: StreamBuilder<List<Order>>(
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

          final orders = snapshot.data ?? [];

          // Filter client-side for WAITING_COURIER
          final availableOrders = orders
              .where((o) => o.status == OrderStatus.waitingCourier)
              .toList();

          // TODO: Sort by R/T (requires OSRM distance data and prep time)
          // For now, keep simple order by delivery price (descending)
          availableOrders.sort((a, b) =>
              b.deliveryPriceUserSet.compareTo(a.deliveryPriceUserSet));

          if (availableOrders.isEmpty) {
            return const CBEmptyState(
              icon: Icons.delivery_dining_outlined,
              title: '目前無可接訂單',
              description: '附近訂單會即時顯示',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: availableOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
            itemBuilder: (context, index) {
              final order = availableOrders[index];
              return _AvailableOrderCard(
                key: Key('courier-available-${order.id}'),
                order: order,
                onAccept: () => _handleAcceptOrder(context, ref, order),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleAcceptOrder(BuildContext context, WidgetRef ref, Order order) async {
    try {
      await ref.read(orderServiceProvider).acceptOrder(order.id);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Stage2GoMerchantPage(order: order),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CBToast.show(
          context: context,
          message: '接單失敗: $e',
          type: CBToastType.error,
        );
      }
    }
  }
}

class _AvailableOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;

  const _AvailableOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final mealPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and delivery fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '訂單 ${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.sp3,
                  vertical: DesignTokens.sp2,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  'NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.brand,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Distance and ETA placeholder
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              const Text(
                '距離 1.5km',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(Icons.timer_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              Text(
                '預估 ${order.prepTimeMinutes ?? 15} 分',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Items summary
          Text(
            '${order.items.length} 項餐點 • NT\$${mealPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Accept button
          CBButton(
            text: '接受訂單',
            onPressed: onAccept,
            size: CBButtonSize.medium,
          ),
        ],
      ),
    );
  }
}

