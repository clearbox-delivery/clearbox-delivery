import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
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
  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('類別管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(menuServiceProvider).getCategories(merchantId),
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

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return CBEmptyState(
              icon: Icons.category_outlined,
              title: '尚無類別',
              description: '新增餐點時會自動建立類別',
              actionLabel: '前往品項管理',
              onAction: () => context.go('/menu'),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex, categories),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                key: Key('cat-${category['id']}'),
                category: category,
                onTap: () => _navigateToItems(category),
                onRename: () => _showRenameCategoryDialog(category),
              );
            },
          );
        },
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex, List<Map<String, dynamic>> categories) {
    // TODO: Backend reorder API not yet available
    CBToast.show(
      context: context,
      message: '排序功能開發中（待後端實作）',
      type: CBToastType.info,
    );
  }

  void _navigateToItems(Map<String, dynamic> category) {
    context.push('/menu/items', extra: category);
  }

  void _showRenameCategoryDialog(Map<String, dynamic> category) {
    // TODO: Category rename requires backend support (current categories are derived from items)
    CBToast.show(
      context: context,
      message: '類別重新命名開發中（待後端實作）',
      type: CBToastType.info,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final VoidCallback onRename;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return CBCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          child: Row(
            children: [
              // Drag handle
              const Icon(Icons.drag_indicator, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp3),

              // Category info
              Expanded(
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

              // Navigate icon
              const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
