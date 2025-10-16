import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';

/// Order Details Bottom Sheet
/// [merchant_app_whitepaper.md Section 5.2]
/// [REQ-MER-HIS-002] Order details with timeline, items, support actions
class OrderDetailsSheet extends ConsumerWidget {
  final Order order;

  const OrderDetailsSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.sp6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '訂單詳情',
                    style: TextStyle(
                      fontSize: DesignTokens.fsXl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.sp4),

              // Basic info
              _buildInfoSection('基本資訊', [
                _buildInfoRow('訂單編號', order.id.substring(0, 12)),
                _buildInfoRow('下單時間', _formatDateTime(order.createdAt)),
                _buildInfoRow('狀態', _getStatusText(order.status)),
                _buildInfoRow('顧客外送費', 'NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}'),
                _buildInfoRow('餐費合計', 'NT\$${mealPrice.toStringAsFixed(0)}'),
              ]),

              const SizedBox(height: DesignTokens.sp6),

              // Items
              _buildInfoSection('餐點明細', order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x ${item.quantity}',
                          style: const TextStyle(fontSize: DesignTokens.fsSm),
                        ),
                      ),
                      Text(
                        'NT\$${item.unitPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: DesignTokens.fsSm,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),

              const SizedBox(height: DesignTokens.sp6),

              // Notes
              if (order.customerNotes != null || order.merchantNotes != null)
                _buildInfoSection('備註', [
                  if (order.customerNotes != null)
                    _buildInfoRow('顧客備註', order.customerNotes!),
                  if (order.merchantNotes != null)
                    _buildInfoRow('店家備註', order.merchantNotes!),
                ]),

              const SizedBox(height: DesignTokens.sp6),

              // Timeline placeholder
              _buildInfoSection('時間軸（開發中）', [
                const Text(
                  '完整事件時間軸需整合 order_events 表',
                  style: TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ]),

              const SizedBox(height: DesignTokens.sp6),

              // Support actions
              Row(
                children: [
                  Expanded(
                    child: CBButton(
                      text: '問題申訴',
                      onPressed: () => _handleIssueReport(context),
                      type: CBButtonType.secondary,
                      size: CBButtonSize.medium,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.sp3),
                  Expanded(
                    child: CBButton(
                      text: '聯絡客服',
                      onPressed: () => _handleContactSupport(context),
                      type: CBButtonType.secondary,
                      size: CBButtonSize.medium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: DesignTokens.fsMd,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp3),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return '已完成';
      case OrderStatus.cancelledMerchant:
        return '店家取消';
      case OrderStatus.cancelledCustomer:
        return '顧客取消';
      case OrderStatus.cancelledCourier:
        return '外送員取消';
      case OrderStatus.expiredUnmatched:
        return '未媒合';
      default:
        return status.value;
    }
  }

  void _handleIssueReport(BuildContext context) {
    // TODO: Implement issue reporting system
    CBToast.show(
      context: context,
      message: '問題申訴功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleContactSupport(BuildContext context) {
    // TODO: Implement customer support contact
    CBToast.show(
      context: context,
      message: '聯絡客服功能開發中',
      type: CBToastType.info,
    );
  }
}

