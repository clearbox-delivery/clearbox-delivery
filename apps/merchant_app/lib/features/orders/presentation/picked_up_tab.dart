import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Picked-up Tab (已取餐，配送中)
/// [merchant_app_whitepaper.md Section 4.4]
/// [REQ-MER-CO-004] Merchant monitors order after courier pickup
class PickedUpTab extends ConsumerWidget {
  const PickedUpTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Center(child: Text('Please login'));
    }

    final ordersStream = ref.watch(realtimeServiceProvider).watchMerchantOrders(merchantId);

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

        // Filter client-side for PICKED_UP (courier picked up, delivering)
        final pickedUpOrders = allOrders
            .where((o) => o.status == OrderStatus.pickedUp)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (pickedUpOrders.isEmpty) {
          return const CBEmptyState(
            icon: Icons.local_shipping_outlined,
            title: '暫無配送中訂單',
            description: '外送員取餐後會進入配送',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          itemCount: pickedUpOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp4),
          itemBuilder: (context, index) {
            final order = pickedUpOrders[index];
            return _PickedUpCard(
              key: Key('picked-up-${order.id}'),
              order: order,
            );
          },
        );
      },
    );
  }
}

class _PickedUpCard extends ConsumerWidget {
  final Order order;

  const _PickedUpCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Icon(Icons.delivery_dining, size: 20, color: DesignTokens.brand),
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
                          '4.9',
                          style: TextStyle(
                            fontSize: DesignTokens.fsSm,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.sp1),
                    const Text(
                      '近七日 28 單 • 機車',
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

          // Delivery ETA and distance (mock)
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: DesignTokens.brand),
              const SizedBox(width: DesignTokens.sp2),
              const Text(
                '送達 ETA: 8 分鐘',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(Icons.location_on_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              const Text(
                '距離 2.1km',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Customer delivery area (privacy-preserving)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.sp3,
              vertical: DesignTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.bgSubtle,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: DesignTokens.textMuted),
                const SizedBox(width: DesignTokens.sp2),
                Expanded(
                  child: Text(
                    '送往：${_getDeliveryArea()}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: CBButton(
                  text: '聯絡外送員',
                  onPressed: () => _handleContactCourier(context),
                  icon: Icons.phone_outlined,
                  variant: CBButtonVariant.secondary,
                  size: CBButtonSize.medium,
                ),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: CBButton(
                  text: '聯絡顧客',
                  onPressed: () => _handleContactCustomer(context),
                  icon: Icons.chat_outlined,
                  variant: CBButtonVariant.secondary,
                  size: CBButtonSize.medium,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Additional actions
          Row(
            children: [
              Expanded(
                child: CBButton(
                  text: '查看路線',
                  onPressed: () => _handleViewRoute(context),
                  icon: Icons.map_outlined,
                  variant: CBButtonVariant.secondary,
                  size: CBButtonSize.small,
                ),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: CBButton(
                  text: '問題通報',
                  onPressed: () => _handleReportIssue(context),
                  icon: Icons.report_problem_outlined,
                  variant: CBButtonVariant.secondary,
                  size: CBButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDeliveryArea() {
    // Privacy-preserving: only show general area (里/路段)
    // TODO: Extract from customer address when available
    return '信義區松仁路段';
  }

  void _handleContactCourier(BuildContext context) {
    // TODO: Implement masked phone/message for courier
    CBToast.show(
      context: context,
      message: '聯絡外送員功能開發中（雙向遮罩保護）',
      type: CBToastType.info,
    );
  }

  void _handleContactCustomer(BuildContext context) {
    // TODO: Implement masked phone/message for customer
    CBToast.show(
      context: context,
      message: '聯絡顧客功能開發中（雙向遮罩保護）',
      type: CBToastType.info,
    );
  }

  void _handleViewRoute(BuildContext context) {
    // TODO: Implement route map view
    CBToast.show(
      context: context,
      message: '路線地圖功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleReportIssue(BuildContext context) {
    // TODO: Implement issue reporting (wrong item, missing sauce, etc.)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('問題通報'),
        content: const Text('請選擇問題類型：\n\n• 外送員取錯\n• 忘記附贈品\n• 其他問題\n\n（完整功能開發中）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}

