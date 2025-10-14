import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';

/// Categories Management Page
/// [merchant_app_whitepaper.md Section 7.1]
/// [REQ-MER-MENU-001] Category list, reorder, and toggle visibility
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  // Mock categories for MVP skeleton
  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'name': '主餐', 'isVisible': true, 'itemCount': 12},
    {'id': '2', 'name': '飲料', 'isVisible': true, 'itemCount': 8},
    {'id': '3', 'name': '甜點', 'isVisible': false, 'itemCount': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('類別管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _categories.isEmpty
          ? const CBEmptyState(
              icon: Icons.category_outlined,
              title: '尚無類別',
              description: '點擊右上角新增類別',
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              itemCount: _categories.length,
              onReorder: _handleReorder,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _CategoryCard(
                  key: Key('cat-${category['id']}'),
                  category: category,
                  onTap: () => _navigateToItems(category),
                  onToggle: (isVisible) => _handleToggleVisibility(index, isVisible),
                  onRename: () => _showRenameCategoryDialog(index),
                  onDelete: () => _handleDelete(index),
                );
              },
            ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    // TODO: Persist order to backend
    CBToast.show(
      context: context,
      message: '排序已更新（待後端實作）',
      type: CBToastType.info,
    );
  }

  void _handleToggleVisibility(int index, bool isVisible) {
    setState(() {
      _categories[index]['isVisible'] = isVisible;
    });

    CBToast.show(
      context: context,
      message: isVisible ? '類別已顯示' : '類別已隱藏',
      type: CBToastType.success,
    );
  }

  void _navigateToItems(Map<String, dynamic> category) {
    context.push('/menu/items', extra: category);
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增類別'),
        content: CBInput(
          label: '類別名稱',
          controller: controller,
          hintText: '例如：主餐、飲料',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _categories.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': controller.text.trim(),
                    'isVisible': true,
                    'itemCount': 0,
                  });
                });
                Navigator.pop(context);
                CBToast.show(
                  context: context,
                  message: '類別已新增',
                  type: CBToastType.success,
                );
              }
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(int index) {
    final controller = TextEditingController(text: _categories[index]['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新命名'),
        content: CBInput(
          label: '類別名稱',
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _categories[index]['name'] = controller.text.trim();
                });
                Navigator.pop(context);
                CBToast.show(
                  context: context,
                  message: '類別已更新',
                  type: CBToastType.success,
                );
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _handleDelete(int index) {
    final categoryName = _categories[index]['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除類別'),
        content: Text('確定要刪除「$categoryName」嗎？此類別下的所有餐點將被移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.removeAt(index);
              });
              Navigator.pop(context);
              CBToast.show(
                context: context,
                message: '類別已刪除',
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
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CBCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Row(
        children: [
          // Drag handle
          const Icon(Icons.drag_indicator, color: DesignTokens.textMuted),
          const SizedBox(width: DesignTokens.sp3),

          // Category info
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontSize: DesignTokens.fsMd,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp1),
                  Text(
                    '${category['itemCount']} 個餐點',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Visibility toggle
          Switch(
            value: category['isVisible'],
            onChanged: onToggle,
            activeColor: DesignTokens.brand,
          ),

          // Actions menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: DesignTokens.textMuted),
            onSelected: (value) {
              if (value == 'rename') {
                onRename();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: DesignTokens.sp2),
                    Text('重新命名'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: DesignTokens.danger),
                    SizedBox(width: DesignTokens.sp2),
                    Text('刪除', style: TextStyle(color: DesignTokens.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

