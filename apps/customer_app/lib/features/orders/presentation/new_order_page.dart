import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:core_data/core_data.dart';

/// New order page with price validation
/// [REQ-CUST-ORDER-001] Customer sets delivery price
class NewOrderPage extends ConsumerStatefulWidget {
  const NewOrderPage({super.key});

  @override
  ConsumerState<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends ConsumerState<NewOrderPage> {
  final _priceController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOrder() async {
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);

    if (price == null) {
      setState(() => _errorMessage = 'Please enter a valid price');
      return;
    }

    // Validate price [TC-CUST-001, TC-CUST-002]
    final validation = PriceValidator.validate(price);
    if (!validation.isValid) {
      setState(() => _errorMessage = validation.message);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderService = ref.read(orderServiceProvider);
      
      // Create order with sample data (MVP)
      await orderService.createOrder(
        merchantId: 'mer-1', // TODO: Get from merchant selection
        items: [
          const OrderItem(
            sku: 'bento-001',
            name: 'Test Bento',
            quantity: 1,
            unitPrice: 100,
          ),
        ],
        deliveryPrice: price,
        customerNotes: 'Test order',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully')),
        );
        _priceController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to create order: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set Delivery Price',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Min: NT\$${PriceValidator.minDeliveryPrice.toInt()}, '
              'Max: NT\$${PriceValidator.maxDeliveryPrice.toInt()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Delivery Price (NT\$)',
                hintText: 'Enter amount',
                errorText: _errorMessage,
                prefixText: 'NT\$ ',
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handleCreateOrder,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Order'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) {
          context.go('/history');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.add_shopping_cart),
          label: 'New Order',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
      ],
    );
  }
}


