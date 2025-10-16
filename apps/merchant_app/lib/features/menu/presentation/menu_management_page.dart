import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/widgets/app_bottom_nav.dart';

/// 商家菜单管理页面
/// [REQ-MER-MENU-001] 菜单 CRUD
class MenuManagementPage extends ConsumerWidget {
  const MenuManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('菜單管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMenuItem(context, ref),
          ),
        ],
      ),
      body: _buildMenuList(context, ref, merchantId),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildMenuList(BuildContext context, WidgetRef ref, String merchantId) {
    return FutureBuilder<Map<String, List<MenuItem>>>(
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
            onAction: () => ref.invalidate(menuServiceProvider),
          );
        }

        final menuByCategory = snapshot.data ?? {};

        if (menuByCategory.isEmpty) {
          return CBEmptyState(
            icon: Icons.restaurant_menu,
            title: '尚無菜單',
            description: '點擊右上角新增餐點',
            actionLabel: '新增餐點',
            onAction: () => _showAddMenuItem(context, ref),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          itemCount: menuByCategory.keys.length,
          itemBuilder: (context, index) {
            final category = menuByCategory.keys.elementAt(index);
            final items = menuByCategory[category]!;

            return _CategorySection(
              category: category,
              items: items,
              onItemTap: (item) => _showEditMenuItem(context, ref, item),
            );
          },
        );
      },
    );
  }

  void _showAddMenuItem(BuildContext context, WidgetRef ref) {
    final merchantId = ref.read(authServiceProvider).currentUserId ?? 'dev-merchant';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuItemForm(merchantId: merchantId),
    );
  }

  void _showEditMenuItem(BuildContext context, WidgetRef ref, MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuItemForm(
        merchantId: ref.read(authServiceProvider).currentUserId ?? 'dev-merchant',
        item: item,
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<MenuItem> items;
  final Function(MenuItem) onItemTap;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.sp4,
            vertical: DesignTokens.sp3,
          ),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: DesignTokens.fsLg,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
          ),
        ),
        ...items.map((item) => CBCard(
          onTap: () => onItemTap(item),
          margin: const EdgeInsets.only(
            left: DesignTokens.sp4,
            right: DesignTokens.sp4,
            bottom: DesignTokens.sp2,
          ),
          child: Row(
            children: [
              // 图片占位
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DesignTokens.bgSubtle,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
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
                    if (item.description != null) ...[
                      const SizedBox(height: DesignTokens.sp1),
                      Text(
                        item.description!,
                        style: const TextStyle(
                          fontSize: DesignTokens.fsSm,
                          color: DesignTokens.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: DesignTokens.sp2),
                    Row(
                      children: [
                        Text(
                          'NT\$${item.price}',
                          style: const TextStyle(
                            fontSize: DesignTokens.fsMd,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.brand,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.sp3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.sp2,
                            vertical: DesignTokens.sp1,
                          ),
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? DesignTokens.accent.withOpacity(0.1)
                                : DesignTokens.textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                          child: Text(
                            item.isAvailable ? '上架中' : '已下架',
                            style: TextStyle(
                              fontSize: DesignTokens.fsXs,
                              color: item.isAvailable
                                  ? DesignTokens.accent
                                  : DesignTokens.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: DesignTokens.sp4),
      ],
    );
  }
}

class _MenuItemForm extends ConsumerStatefulWidget {
  final String merchantId;
  final MenuItem? item;

  const _MenuItemForm({required this.merchantId, this.item});

  @override
  ConsumerState<_MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends ConsumerState<_MenuItemForm> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  String? _volumeLevel;
  String? _weightLevel;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _descController = TextEditingController(text: widget.item?.description);
    _priceController = TextEditingController(
      text: widget.item?.price.toString() ?? '',
    );
    _categoryController = TextEditingController(text: widget.item?.category);
    _volumeLevel = widget.item?.volumeLevel;
    _weightLevel = widget.item?.weightLevel;
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showError('請輸入有效價格');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final menuService = ref.read(menuServiceProvider);

      if (widget.item == null) {
        // 新增
        await menuService.createMenuItem(
          merchantId: widget.merchantId,
          category: _categoryController.text.trim(),
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          price: price,
          volumeLevel: _volumeLevel,
          weightLevel: _weightLevel,
        );
      } else {
        // 更新
        await menuService.updateMenuItem(
          itemId: widget.item!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          price: price,
          isAvailable: _isAvailable,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('儲存成功'),
            backgroundColor: DesignTokens.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('儲存失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.sp6,
            right: DesignTokens.sp6,
            top: DesignTokens.sp6,
            bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.sp6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? '新增餐點' : '編輯餐點',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsXl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp6),

                CBInput(label: '分類', controller: _categoryController),
                const SizedBox(height: DesignTokens.sp4),

                CBInput(label: '餐點名稱', controller: _nameController),
                const SizedBox(height: DesignTokens.sp4),

                CBInput(
                  label: '說明',
                  controller: _descController,
                  maxLines: 3,
                ),
                const SizedBox(height: DesignTokens.sp4),

                CBInput(
                  label: '價格',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: DesignTokens.sp4),

                if (widget.item != null) ...[
                  Row(
                    children: [
                      const Text('上架狀態：'),
                      Switch(
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() => _isAvailable = value);
                        },
                      ),
                      Text(_isAvailable ? '上架' : '下架'),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.sp4),
                ],

                const SizedBox(height: DesignTokens.sp6),

                CBButton(
                  text: '儲存',
                  onPressed: _isLoading ? null : _handleSave,
                  isLoading: _isLoading,
                  size: CBButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

