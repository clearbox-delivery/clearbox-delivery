import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';

/// Current orders page with 4 tabs and real-time updates
/// [REQ-MER-CO-001, REQ-MER-CO-002] Confirm orders, ≤2s visibility
class CurrentOrdersPage extends ConsumerStatefulWidget {
  const CurrentOrdersPage({super.key});

  @override
  ConsumerState<CurrentOrdersPage> createState() => _CurrentOrdersPageState();
}

class _CurrentOrdersPageState extends ConsumerState<CurrentOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '待确认'),
            Tab(text: '待接单'),
            Tab(text: '备餐中'),
            Tab(text: '已取餐'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersTab(
            merchantId: merchantId,
            status: OrderStatus.pendingStoreConfirm,
          ),
          _OrdersTab(
            merchantId: merchantId,
            status: OrderStatus.waitingCourier,
          ),
          _OrdersTab(
            merchantId: merchantId,
            status: OrderStatus.courierAssigned,
          ),
          _OrdersTab(
            merchantId: merchantId,
            status: OrderStatus.pickedUp,
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  final String merchantId;
  final OrderStatus status;

  const _OrdersTab({
    required this.merchantId,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersStream = ref.watch(merchantOrdersStreamProvider(
      MerchantOrdersQuery(merchantId: merchantId, status: status),
    ));

    return ordersStream.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Text('No orders'));
        }

        return SafeOrderList(
          orders: orders,
          itemBuilder: (order) => OrderCard(
            key: Key('order-card-${order.id}'),
            order: order,
            showHighlight: _isNewOrder(order),
            onTap: () => _showOrderDetail(context, ref, order),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  bool _isNewOrder(Order order) {
    final now = DateTime.now();
    final diff = now.difference(order.createdAt);
    return diff.inSeconds <= 5; // Highlight for 5 seconds
  }

  void _showOrderDetail(BuildContext context, WidgetRef ref, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _OrderDetailSheet(order: order),
    );
  }
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  final Order order;

  const _OrderDetailSheet({required this.order});

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  final _prepTimeController = TextEditingController(text: '15');
  bool _isLoading = false;

  @override
  void dispose() {
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    final prepTime = int.tryParse(_prepTimeController.text);
    if (prepTime == null || prepTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid prep time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      await orderService.merchantConfirmOrder(
        orderId: widget.order.id,
        prepTimeMinutes: prepTime,
        merchantNotes: 'Confirmed',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order confirmed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm: $e')),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Order Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              Text('Order ID: ${widget.order.id.substring(0, 8)}'),
              Text('Delivery Fee: NT\$${widget.order.deliveryPriceUserSet}'),
              const SizedBox(height: 16),
              
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.order.items.map((item) => ListTile(
                title: Text(item.name),
                subtitle: Text('Qty: ${item.quantity}'),
                trailing: Text('NT\$${item.unitPrice}'),
              )),
              
              if (widget.order.status == OrderStatus.pendingStoreConfirm) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _prepTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prep Time (minutes)',
                    hintText: 'e.g., 15',
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmOrder,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm Order'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


