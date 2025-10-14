import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';

/// Order Details Bottom Sheet
/// [customer_app_whitepaper.md Section 5]
class OrderDetailsSheet extends ConsumerWidget {
  final Order order;

  const OrderDetailsSheet({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.sp6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '訂單詳情',
                  style: TextStyle(
                    fontSize: DesignTokens.fsXl,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: DesignTokens.textMuted,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.sp6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID and date
                  _buildInfoRow('訂單編號', order.id.substring(0, 8)),
                  _buildInfoRow('下單時間', order.createdAt.toString()),
                  _buildInfoRow('狀態', order.status.toString()),

                  const SizedBox(height: DesignTokens.sp6),
                  const Divider(),
                  const SizedBox(height: DesignTokens.sp6),

                  // Items
                  const Text(
                    '訂單內容',
                    style: TextStyle(
                      fontSize: DesignTokens.fsLg,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp4),
                  ...order.items.map((item) => _buildItemRow(item)),

                  const SizedBox(height: DesignTokens.sp6),
                  const Divider(),
                  const SizedBox(height: DesignTokens.sp6),

                  // Pricing
                  _buildInfoRow('餐費', 'NT\$${order.mealPrice.toStringAsFixed(0)}'),
                  _buildInfoRow('外送費', 'NT\$${order.deliveryPrice.toStringAsFixed(0)}'),
                  _buildInfoRow(
                    '總計',
                    'NT\$${(order.mealPrice + order.deliveryPrice).toStringAsFixed(0)}',
                    isTotal: true,
                  ),

                  const SizedBox(height: DesignTokens.sp8),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(DesignTokens.sp6),
            child: Row(
              children: [
                Expanded(
                  child: CBButton(
                    text: '評價店家',
                    onPressed: () {
                      // TODO: Navigate to rating page
                      Navigator.pop(context);
                    },
                    variant: CBButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: DesignTokens.sp4),
                Expanded(
                  child: CBButton(
                    text: '再買一次',
                    onPressed: () {
                      // TODO: Clone order and navigate to new order
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? DesignTokens.fsLg : DesignTokens.fsMd,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: DesignTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? DesignTokens.fsLg : DesignTokens.fsMd,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: DesignTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.name} × ${item.quantity}',
              style: const TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textPrimary,
              ),
            ),
          ),
          Text(
            'NT\$${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: DesignTokens.fsMd,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

