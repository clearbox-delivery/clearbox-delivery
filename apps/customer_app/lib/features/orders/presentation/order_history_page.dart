import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/features/orders/presentation/order_details_sheet.dart';
import 'package:customer_app/widgets/app_bottom_nav.dart';

/// Order History Page
/// [customer_app_whitepaper.md Section 5]
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('歷史訂單'),
      ),
      body: FutureBuilder<List<Order>>(
        future: ref.read(orderServiceProvider).getCustomerOrders(userId),
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

          if (orders.isEmpty) {
            return const CBEmptyState(
              icon: Icons.receipt_long_outlined,
              title: '尚無訂單',
              description: '完成的訂單會顯示在這裡',
            );
          }

          // Sort by date descending (newest first)
          final sortedOrders = List<Order>.from(orders)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.sp6),
            itemCount: sortedOrders.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: DesignTokens.sp4),
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '店家名稱', // TODO: Fetch merchant name
                  style: const TextStyle(
                    fontSize: DesignTokens.fsLg,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_more, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: OrderDetailsSheet(order: order),
                    ),
                  );
                },
                color: DesignTokens.brand,
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp2),

          // Date and time
          Text(
            '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')} '
            '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Duration (if completed)
          if (order.status == OrderStatus.delivered) ...[
            Text(
              '配送時長: ${_calculateDuration(order)} 分鐘',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.sp3),
          ],

          // Pricing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '餐費',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              Text(
                'NT\$—',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp2),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '外送費',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              Text(
                'NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateDuration(Order order) {
    // TODO: Calculate from order events (accepted_at to delivered_at)
    return '--';
  }
}
