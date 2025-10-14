import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';

/// Order Details Bottom Sheet
/// [REQ-COU-HIS-002] Show order details
class OrderDetailsSheet extends StatelessWidget {
  final Order order;

  const OrderDetailsSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final mealPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final totalPrice = mealPrice + order.deliveryPriceUserSet;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: DesignTokens.bg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: DesignTokens.sp2),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(DesignTokens.sp4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '訂單詳情',
                      style: const TextStyle(
                        fontSize: DesignTokens.fsLg,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DesignTokens.sp4),
                  children: [
                    _buildInfoRow('訂單編號', order.id.substring(0, 16)),
                    _buildInfoRow('狀態', _getStatusText(order.status)),
                    _buildInfoRow('建立時間', _formatDateTime(order.createdAt)),
                    _buildInfoRow('完成時間', _formatDateTime(order.updatedAt)),
                    const SizedBox(height: DesignTokens.sp4),
                    const Text(
                      '餐點明細',
                      style: TextStyle(
                        fontSize: DesignTokens.fsMd,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.sp2),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.name} x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: DesignTokens.fsSm,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              Text(
                                'NT\$${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: DesignTokens.fsSm,
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: DesignTokens.sp4),
                    _buildPriceRow('餐點小計', mealPrice),
                    _buildPriceRow('外送費', order.deliveryPriceUserSet),
                    const SizedBox(height: DesignTokens.sp2),
                    _buildPriceRow('總計', totalPrice, isTotal: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  Widget _buildPriceRow(String label, double price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? DesignTokens.fsMd : DesignTokens.fsSm,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: DesignTokens.textPrimary,
            ),
          ),
          Text(
            'NT\$${price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? DesignTokens.fsMd : DesignTokens.fsSm,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? DesignTokens.brand : DesignTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return '已完成';
      case OrderStatus.cancelledCustomer:
        return '顧客取消';
      case OrderStatus.cancelledMerchant:
        return '店家取消';
      case OrderStatus.cancelledCourier:
        return '外送員取消';
      default:
        return status.toString();
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

