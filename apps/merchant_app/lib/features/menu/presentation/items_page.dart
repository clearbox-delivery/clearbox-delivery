import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
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

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(widget.category['name']),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedIds.isEmpty ? null : () => _handleBatchDelete(merchantId),
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
      body: FutureBuilder<Map<String, List<MenuItem>>>(
        future: ref.read(menuServiceProvider).getMenuByCategory(merchantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CBLoadingIndicator());
          }

          if (snapshot.hasError) {
            return CBErrorState(
              title: '載入失敗',
              description: snapshot.error.toString(),
              actionLabel: '重試',
              onAction: () => setState(() {}),
            );
          }

          final menuMap = snapshot.data ?? {};
          final items = menuMap[widget.category['name']] ?? [];

          if (items.isEmpty) {
            return CBEmptyState(
              icon: Icons.restaurant_outlined,
              title: '尚無餐點',
              description: '點擊右上角新增餐點',
              actionLabel: '新增餐點',
              onAction: () => _navigateToEditItem(null),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedIds.contains(item.id);

              return _ItemCard(
                key: Key('item-${item.id}'),
                item: item,
                isSelectionMode: _isSelectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(item.id);
                  } else {
                    _navigateToEditItem(item);
                  }
                },
                onToggleAvailability: (isAvailable) =>
                    _handleToggleAvailability(item, isAvailable),
              );
            },
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

  Future<void> _handleToggleAvailability(MenuItem item, bool isAvailable) async {
    try {
      await ref.read(menuServiceProvider).updateMenuItem(
        itemId: item.id,
        isAvailable: isAvailable,
      );

      if (mounted) {
        setState(() {}); // Refresh
        CBToast.show(
          context: context,
          message: isAvailable ? '已上架' : '已下架',
          type: CBToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CBToast.show(
          context: context,
          message: '操作失敗: $e',
          type: CBToastType.error,
        );
      }
    }
  }

  Future<void> _handleBatchDelete(String merchantId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批次刪除'),
        content: Text('確定要刪除 ${_selectedIds.length} 個餐點嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.danger),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (final id in _selectedIds) {
          await ref.read(menuServiceProvider).deleteMenuItem(id);
        }

        if (mounted) {
          setState(() {
            _selectedIds.clear();
            _isSelectionMode = false;
          });
          CBToast.show(
            context: context,
            message: '餐點已刪除',
            type: CBToastType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          CBToast.show(
            context: context,
            message: '刪除失敗: $e',
            type: CBToastType.error,
          );
        }
      }
    }
  }

  void _navigateToEditItem(MenuItem? item) {
    context.push('/menu/items/edit', extra: {
      'category': widget.category,
      'item': item,
    });
  }
}

class _ItemCard extends StatelessWidget {
  final MenuItem item;
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
                  item.name,
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp1),
                Text(
                  'NT\$${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.brand,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp2),
                Row(
                  children: [
                    _buildTag('庫存 ${item.stockQuantity ?? 0}', DesignTokens.textMuted),
                    const SizedBox(width: DesignTokens.sp2),
                    _buildTag('${item.prepTimeMinutes ?? 15}分', DesignTokens.textSecondary),
                    if (item.volumeLevel != null) ...[
                      const SizedBox(width: DesignTokens.sp2),
                      _buildTag(item.volumeLevel!, DesignTokens.brand),
                    ],
                    if (item.weightLevel != null) ...[
                      const SizedBox(width: DesignTokens.sp2),
                      _buildTag(item.weightLevel!, DesignTokens.accent),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Availability toggle
          if (!isSelectionMode)
            Switch(
              value: item.isAvailable,
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
