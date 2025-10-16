import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';
import 'package:courier_app/features/history/presentation/order_details_sheet.dart';

/// Courier Order History Page
/// [courier_app_whitepaper.md Section 5]
/// [REQ-COU-HIS-001] History with filters and details
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  OrderStatus? _statusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final courierId = authService.currentUserId;

    if (courierId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('歷史訂單'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: ref.read(orderServiceProvider).getCourierHistory(
              courierId: courierId,
              from: _startDate,
              to: _endDate,
            ),
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

          var orders = snapshot.data ?? [];

          // Client-side filtering
          if (_statusFilter != null) {
            orders = orders.where((o) => o.status == _statusFilter).toList();
          }

          if (_searchQuery.isNotEmpty) {
            orders = orders.where((o) {
              return o.id.contains(_searchQuery) ||
                  o.merchantId.contains(_searchQuery) ||
                  o.customerId.contains(_searchQuery);
            }).toList();
          }

          if (orders.isEmpty) {
            return const CBEmptyState(
              icon: Icons.receipt_long_outlined,
              title: '暫無訂單',
              description: '完成的訂單會在此顯示',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderHistoryCard(
                order: order,
                onTap: () => _showOrderDetails(context, order),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '篩選',
              style: TextStyle(
                fontSize: DesignTokens.fsLg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.sp4),
            CBInput(
              labelText: '搜尋',
              hintText: '訂單編號或關鍵字',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: DesignTokens.sp4),
            CBButton(
              text: '套用',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderDetailsSheet(order: order),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    ) + order.deliveryPriceUserSet;

    return CBCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: DesignTokens.sp2),
          Text(
            '完成時間: ${_formatDateTime(order.updatedAt)}',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '餐費: NT\$${(totalPrice - order.deliveryPriceUserSet).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              Text(
                '外送費: NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.delivered:
        bgColor = DesignTokens.brand.withOpacity(0.1);
        textColor = DesignTokens.brand;
        label = '已完成';
        break;
      case OrderStatus.cancelledCustomer:
      case OrderStatus.cancelledMerchant:
      case OrderStatus.cancelledCourier:
        bgColor = DesignTokens.danger.withOpacity(0.1);
        textColor = DesignTokens.danger;
        label = '已取消';
        break;
      default:
        bgColor = DesignTokens.bgSubtle;
        textColor = DesignTokens.textSecondary;
        label = status.toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp2,
        vertical: DesignTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.fsXs,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

