import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:domain/domain.dart';

/// Available orders page with R/T sorting
/// [REQ-COU-MATCH-003] Courier accepts order with conflict handling
class AvailableOrdersPage extends ConsumerWidget {
  const AvailableOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Orders'),
      ),
      body: FutureBuilder(
        future: ref.read(orderServiceProvider).getAvailableOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No available orders'));
          }

          // Sort by R/T priority [TC-COU-SORT-001]
          final sortedOrders = _sortByPriority(orders);

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh list
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedOrders.length,
              itemBuilder: (context, index) {
                final order = sortedOrders[index];
                return OrderCard(
                  order: order,
                  onTap: () => _showAcceptDialog(context, ref, order),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Order> _sortByPriority(List<Order> orders) {
    // Simple MVP sorting - in production, use actual location & distances
    final priorities = orders.map((order) {
      final priority = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: order.deliveryPriceUserSet,
        travelTimeToMerchantMinutes: 10, // Mock
        prepTimeMinutes: order.prepTimeMinutes?.toDouble() ?? 15,
        deliveryTimeMinutes: 15, // Mock
      );

      return MapEntry(order, priority);
    }).toList();

    priorities.sort((a, b) => b.value.compareTo(a.value));
    return priorities.map((e) => e.key).toList();
  }

  void _showAcceptDialog(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (context) => _AcceptOrderDialog(order: order),
    );
  }
}

class _AcceptOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const _AcceptOrderDialog({required this.order});

  @override
  ConsumerState<_AcceptOrderDialog> createState() => _AcceptOrderDialogState();
}

class _AcceptOrderDialogState extends ConsumerState<_AcceptOrderDialog> {
  bool _isLoading = false;

  Future<void> _acceptOrder() async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final result = await orderService.acceptOrder(widget.order.id);

      if (!result.success) {
        // Handle conflict [TC-COU-ACPT-001]
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Order already accepted'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Accept Order?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order ID: ${widget.order.id.substring(0, 8)}'),
          Text('Delivery Fee: NT\$${widget.order.deliveryPriceUserSet}'),
          Text('Items: ${widget.order.items.length}'),
          if (widget.order.prepTimeMinutes != null)
            Text('Prep Time: ${widget.order.prepTimeMinutes} min'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _acceptOrder,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Accept'),
        ),
      ],
    );
  }
}


