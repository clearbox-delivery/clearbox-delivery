import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';

/// Menu Items List Page
/// [merchant_app_whitepaper.md Section 7.2]
/// [REQ-MER-MENU-002] Item list with thumbnail, price, stock, prep time, volume/weight tags
class ItemsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> category;

  const ItemsPage({super.key, required this.category});

  @override
  ConsumerState<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends ConsumerState<ItemsPage> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  // Mock items for MVP skeleton
  final List<Map<String, dynamic>> _items = [
    {
      'id': 'item1',
      'name': '招牌炒飯',
      'description': '經典蛋炒飯加料',
      'price': 80,
      'isAvailable': true,
      'stock': 20,
      'prepTimeMinutes': 10,
      'volumeLevel': 'V2',
      'weightLevel': 'W2',
    },
    {
      'id': 'item2',
      'name': '宮保雞丁',
      'description': '辣度適中',
      'price': 120,
      'isAvailable': true,
      'stock': 15,
      'prepTimeMinutes': 15,
      'volumeLevel': 'V2',
      'weightLevel': 'W3',
    },
    {
      'id': 'item3',
      'name': '紅燒牛肉麵',
      'description': '大份量',
      'price': 150,
      'isAvailable': false,
      'stock': 0,
      'prepTimeMinutes': 20,
      'volumeLevel': 'V3',
      'weightLevel': 'W4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(widget.category['name']),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedIds.isEmpty ? null : _handleBatchDelete,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _enterSelectionMode,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToEditItem(null),
            ),
          ],
        ],
      ),
      body: _items.isEmpty
          ? CBEmptyState(
              icon: Icons.restaurant_outlined,
              title: '尚無餐點',
              description: '點擊右上角新增餐點',
              actionLabel: '新增餐點',
              onAction: () => _navigateToEditItem(null),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = _selectedIds.contains(item['id']);

                return _ItemCard(
                  key: Key('item-${item['id']}'),
                  item: item,
                  isSelectionMode: _isSelectionMode,
                  isSelected: isSelected,
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(item['id']);
                    } else {
                      _navigateToEditItem(item);
                    }
                  },
                  onToggleAvailability: (isAvailable) =>
                      _handleToggleAvailability(index, isAvailable),
                );
              },
            ),
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _handleToggleAvailability(int index, bool isAvailable) {
    setState(() {
      _items[index]['isAvailable'] = isAvailable;
    });

    CBToast.show(
      context: context,
      message: isAvailable ? '已上架' : '已下架',
      type: CBToastType.success,
    );
  }

  void _handleBatchDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批次刪除'),
        content: Text('確定要刪除 ${_selectedIds.length} 個餐點嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.removeWhere((item) => _selectedIds.contains(item['id']));
                _selectedIds.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(context);
              CBToast.show(
                context: context,
                message: '餐點已刪除',
                type: CBToastType.success,
              );
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.danger),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditItem(Map<String, dynamic>? item) {
    context.push('/menu/items/edit', extra: {
      'category': widget.category,
      'item': item,
    });
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleAvailability;

  const _ItemCard({
    super.key,
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return CBCard(
      onTap: onTap,
      child: Row(
        children: [
          // Selection checkbox
          if (isSelectionMode) ...[
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: DesignTokens.brand,
            ),
            const SizedBox(width: DesignTokens.sp2),
          ],

          // Thumbnail
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DesignTokens.bgSubtle,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: const Icon(Icons.restaurant, color: DesignTokens.textMuted),
          ),

          const SizedBox(width: DesignTokens.sp4),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp1),
                Text(
                  'NT\$${item['price']}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.brand,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp2),
                Row(
                  children: [
                    _buildTag('庫存 ${item['stock']}', DesignTokens.textMuted),
                    const SizedBox(width: DesignTokens.sp2),
                    _buildTag('${item['prepTimeMinutes']}分', DesignTokens.textSecondary),
                    const SizedBox(width: DesignTokens.sp2),
                    _buildTag(item['volumeLevel'], DesignTokens.brand),
                    const SizedBox(width: DesignTokens.sp2),
                    _buildTag(item['weightLevel'], DesignTokens.accent),
                  ],
                ),
              ],
            ),
          ),

          // Availability toggle
          if (!isSelectionMode)
            Switch(
              value: item['isAvailable'],
              onChanged: onToggleAvailability,
              activeColor: DesignTokens.brand,
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp2,
        vertical: DesignTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: DesignTokens.fsXs,
          color: color,
        ),
      ),
    );
  }
}

