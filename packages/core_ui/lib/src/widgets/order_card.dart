import 'package:flutter/material.dart';
import 'package:core_data/core_data.dart';
import 'package:intl/intl.dart';

/// Order card widget for lists
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
    final timeFormat = DateFormat('HH:mm');
    
    return Card(
      key: Key('order-card-${order.id}'),
      color: showHighlight ? Colors.yellow.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                timeFormat.format(order.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} items',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery Fee:',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pendingStoreConfirm:
        color = Colors.orange;
        label = 'Pending Confirm';
        break;
      case OrderStatus.waitingCourier:
        color = Colors.blue;
        label = 'Waiting Courier';
        break;
      case OrderStatus.courierAssigned:
        color = Colors.purple;
        label = 'Assigned';
        break;
      case OrderStatus.pickedUp:
        color = Colors.teal;
        label = 'Picked Up';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        label = 'Delivered';
        break;
      default:
        color = Colors.grey;
        label = 'Cancelled';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}


