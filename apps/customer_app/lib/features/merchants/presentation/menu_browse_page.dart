import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:go_router/go_router.dart';

/// 菜单浏览页面
/// 顾客选择商品并下单
class MenuBrowsePage extends ConsumerStatefulWidget {
  final Merchant merchant;

  const MenuBrowsePage({
    super.key,
    required this.merchant,
  });

  @override
  ConsumerState<MenuBrowsePage> createState() => _MenuBrowsePageState();
}

class _MenuBrowsePageState extends ConsumerState<MenuBrowsePage> {
  final Map<String, int> _selectedItems = {}; // itemId -> quantity
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _addItem(MenuItem item) {
    setState(() {
      _selectedItems[item.id] = (_selectedItems[item.id] ?? 0) + 1;
    });
  }

  void _removeItem(MenuItem item) {
    setState(() {
      final qty = _selectedItems[item.id] ?? 0;
      if (qty > 1) {
        _selectedItems[item.id] = qty - 1;
      } else {
        _selectedItems.remove(item.id);
      }
    });
  }

  double _calculateTotal(List<MenuItem> allItems) {
    double total = 0;
    for (final entry in _selectedItems.entries) {
      final item = allItems.firstWhere((i) => i.id == entry.key);
      total += item.price * entry.value;
    }
    return total;
  }

  Future<void> _handleOrder() async {
    if (_selectedItems.isEmpty) {
      _showError('請選擇商品');
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      _showError('請輸入外送費');
      return;
    }

    final validation = PriceValidator.validate(price);
    if (!validation.isValid) {
      _showError(validation.message ?? '價格無效');
      return;
    }

    try {
      final orderService = ref.read(orderServiceProvider);

      // 构建订单项目
      final menuService = ref.read(menuServiceProvider);
      final allItems = await menuService.getMerchantMenu(widget.merchant.id);

      final orderItems = _selectedItems.entries.map((entry) {
        final item = allItems.firstWhere((i) => i.id == entry.key);
        return OrderItem(
          sku: item.id,
          name: item.name,
          quantity: entry.value,
          unitPrice: item.price,
          volumeLevel: item.volumeLevel,
          weightLevel: item.weightLevel,
        );
      }).toList();

      await orderService.createOrder(
        merchantId: widget.merchant.id,
        items: orderItems,
        deliveryPrice: price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('訂單已建立'),
            backgroundColor: DesignTokens.accent,
          ),
        );
        context.go('/new-order');
      }
    } catch (e) {
      if (mounted) {
        _showError('下單失敗: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(widget.merchant.name),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: ref.read(menuServiceProvider).getMerchantMenu(widget.merchant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CBLoadingIndicator());
          }

          final items = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.sp4),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final qty = _selectedItems[item.id] ?? 0;

                    return CBCard(
                      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: DesignTokens.fsMd,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.description != null) ...[
                                  const SizedBox(height: DesignTokens.sp1),
                                  Text(
                                    item.description!,
                                    style: const TextStyle(
                                      fontSize: DesignTokens.fsSm,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: DesignTokens.sp2),
                                Text(
                                  'NT\$${item.price}',
                                  style: const TextStyle(
                                    fontSize: DesignTokens.fsMd,
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (qty > 0) ...[
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeItem(item),
                            ),
                            Text('$qty'),
                          ],
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: DesignTokens.brand,
                            onPressed: () => _addItem(item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 底部购物车
              if (_selectedItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(DesignTokens.sp6),
                  decoration: const BoxDecoration(
                    color: DesignTokens.bg,
                    border: Border(
                      top: BorderSide(color: DesignTokens.border),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('商品小計：'),
                          Text(
                            'NT\$${_calculateTotal(items).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: DesignTokens.fsMd,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.sp4),
                      CBInput(
                        label: '設定外送費',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        hintText: 'NT\$ 30-5000',
                      ),
                      const SizedBox(height: DesignTokens.sp4),
                      CBButton(
                        text: '確認下單',
                        onPressed: _handleOrder,
                        size: CBButtonSize.large,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

