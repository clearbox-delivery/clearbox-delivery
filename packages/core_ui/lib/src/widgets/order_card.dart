import 'package:flutter/material.dart';
import 'package:core_data/core_data.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// Order card widget using design tokens
/// [UI_GUIDELINES.md] Card specifications
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool showHighlight;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('order-card-${order.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp4,
        vertical: DesignTokens.sp2,
      ),
      decoration: BoxDecoration(
        color: showHighlight
            ? const Color(0xFFFEF3C7) // Subtle yellow highlight
            : DesignTokens.bg,
        border: Border.all(
          color: showHighlight ? DesignTokens.warn : DesignTokens.border,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: [DesignTokens.shadowSm],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.sp6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '訂單 #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fsMd,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: DesignTokens.sp3),
                Text(
                  _formatDateTime(order.createdAt),
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: DesignTokens.fsSm,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp3),
                Text(
                  '${order.items.length} 項商品',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '外送費：',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: DesignTokens.fsSm,
                      ),
                    ),
                    Text(
                      'NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fsMd,
                        color: DesignTokens.textPrimary,
                      ),
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

  Widget _buildStatusBadge(OrderStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.pendingStoreConfirm:
        bgColor = const Color(0xFFFEF3C7); // Warn light
        textColor = const Color(0xFF92400E); // Warn dark
        label = '待確認';
        break;
      case OrderStatus.waitingCourier:
        bgColor = const Color(0xFFDDEAFE); // Brand light
        textColor = const Color(0xFF1E40AF); // Brand dark
        label = '待接單';
        break;
      case OrderStatus.courierAssigned:
        bgColor = const Color(0xFFE0E7FF); // Purple light
        textColor = const Color(0xFF5B21B6); // Purple dark
        label = '已指派';
        break;
      case OrderStatus.pickedUp:
        bgColor = const Color(0xFFCCFBF1); // Teal light
        textColor = const Color(0xFF115E59); // Teal dark
        label = '已取餐';
        break;
      case OrderStatus.delivered:
        bgColor = const Color(0xFFD1FAE5); // Accent light
        textColor = const Color(0xFF065F46); // Accent dark
        label = '已送達';
        break;
      default:
        bgColor = const Color(0xFFF1F5F9); // Gray light
        textColor = const Color(0xFF475569); // Gray dark
        label = '已取消';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp3,
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}


