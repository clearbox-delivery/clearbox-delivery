import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/widgets/app_bottom_nav.dart';
import 'package:merchant_app/features/history/presentation/order_details_sheet.dart';

/// Merchant Order History Page
/// [merchant_app_whitepaper.md Section 5]
/// [REQ-MER-HIS-001] Time range, status filter, search, CSV export, order details
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  String _timeRange = 'today'; // today, week, month, custom
  OrderStatus? _statusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('歷史訂單'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _handleCSVExport,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildOrdersList(merchantId),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp4,
        vertical: DesignTokens.sp3,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('今日', _timeRange == 'today', () {
              setState(() => _timeRange = 'today');
            }),
            const SizedBox(width: DesignTokens.sp2),
            _buildChip('本週', _timeRange == 'week', () {
              setState(() => _timeRange = 'week');
            }),
            const SizedBox(width: DesignTokens.sp2),
            _buildChip('本月', _timeRange == 'month', () {
              setState(() => _timeRange = 'month');
            }),
            const SizedBox(width: DesignTokens.sp2),
            if (_statusFilter != null) ...[
              _buildChip(_getStatusLabel(_statusFilter!), true, () {
                setState(() => _statusFilter = null);
              }, isRemovable: true),
              const SizedBox(width: DesignTokens.sp2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, {bool isRemovable = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.sp3,
          vertical: DesignTokens.sp2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.brand : DesignTokens.bgSubtle,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fsSm,
                color: isSelected ? DesignTokens.textOnInverse : DesignTokens.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (isRemovable) ...[
              const SizedBox(width: DesignTokens.sp1),
              Icon(
                Icons.close,
                size: 16,
                color: isSelected ? DesignTokens.textOnInverse : DesignTokens.textPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(String merchantId) {
    return FutureBuilder<List<Order>>(
      future: ref.read(orderServiceProvider).getHistoricalOrders(
        merchantId: merchantId,
        timeRange: _timeRange,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CBLoadingIndicator());
        }

        if (snapshot.hasError) {
          return CBErrorState(
            title: '載入失敗',
            description: snapshot.error.toString(),
            actionLabel: '重試',
            onAction: () => setState(() {}),
          );
        }

        var orders = snapshot.data ?? [];

        // Client-side filtering
        if (_statusFilter != null) {
          orders = orders.where((o) => o.status == _statusFilter).toList();
        }
        if (_searchQuery.isNotEmpty) {
          orders = orders.where((o) =>
            o.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        if (orders.isEmpty) {
          return const CBEmptyState(
            icon: Icons.receipt_long_outlined,
            title: '尚無歷史訂單',
            description: '完成的訂單會在此顯示',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(
              key: Key('history-${order.id}'),
              order: order,
              onTap: () => _showOrderDetails(order),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: DesignTokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.sp6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '篩選條件',
                  style: TextStyle(
                    fontSize: DesignTokens.fsLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp4),
                CBInput(
                  label: '搜尋訂單編號',
                  hintText: '輸入訂單編號...',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: DesignTokens.sp4),
                const Text('狀態', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: DesignTokens.sp2),
                Wrap(
                  spacing: DesignTokens.sp2,
                  children: [
                    ChoiceChip(
                      label: const Text('已完成'),
                      selected: _statusFilter == OrderStatus.delivered,
                      onSelected: (selected) {
                        setState(() => _statusFilter = selected ? OrderStatus.delivered : null);
                        Navigator.pop(context);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('已取消'),
                      selected: _statusFilter == OrderStatus.cancelledMerchant,
                      onSelected: (selected) {
                        setState(() => _statusFilter = selected ? OrderStatus.cancelledMerchant : null);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCSVExport() {
    // TODO: Implement CSV export functionality
    CBToast.show(
      context: context,
      message: 'CSV 匯出功能開發中',
      type: CBToastType.info,
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsSheet(order: order),
    );
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return '已完成';
      case OrderStatus.cancelledMerchant:
        return '店家取消';
      case OrderStatus.cancelledCustomer:
        return '顧客取消';
      case OrderStatus.expiredUnmatched:
        return '未媒合';
      default:
        return '其他';
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mealPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

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
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: DesignTokens.sp2),
          Text(
            _formatDateTime(order.createdAt),
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
                '餐費 NT\$${mealPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: DesignTokens.fsSm),
              ),
              Text(
                '外送費 NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: DesignTokens.fsSm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.delivered:
        color = DesignTokens.accent;
        label = '已完成';
        break;
      case OrderStatus.cancelledMerchant:
      case OrderStatus.cancelledCustomer:
      case OrderStatus.cancelledCourier:
        color = DesignTokens.danger;
        label = '已取消';
        break;
      case OrderStatus.expiredUnmatched:
        color = DesignTokens.textMuted;
        label = '未媒合';
        break;
      default:
        color = DesignTokens.textSecondary;
        label = '其他';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp2,
        vertical: DesignTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.fsXs,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
