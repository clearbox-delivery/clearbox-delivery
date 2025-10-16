import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Edit Menu Item Page
/// [merchant_app_whitepaper.md Section 7.3]
/// [REQ-MER-MENU-003] Full item form with name, price, photo, description, prep time, volume/weight levels, options, stock
class EditItemPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> category;
  final MenuItem? item;

  const EditItemPage({
    super.key,
    required this.category,
    this.item,
  });

  @override
  ConsumerState<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends ConsumerState<EditItemPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _prepTimeController;
  late TextEditingController _stockController;

  String _volumeLevel = 'V1';
  String _weightLevel = 'W1';
  bool _isAvailable = true;
  bool _autoOffOnSoldOut = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name);
    _descController = TextEditingController(text: item?.description);
    _priceController = TextEditingController(
      text: item?.price.toStringAsFixed(0) ?? '',
    );
    _prepTimeController = TextEditingController(
      text: (item?.prepTimeMinutes ?? 15).toString(),
    );
    _stockController = TextEditingController(
      text: (item?.stockQuantity ?? 50).toString(),
    );

    if (item != null) {
      _volumeLevel = item.volumeLevel ?? 'V1';
      _weightLevel = item.weightLevel ?? 'W1';
      _isAvailable = item.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(isEdit ? '編輯餐點' : '新增餐點'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: Text(
              '儲存',
              style: TextStyle(
                color: _isLoading ? DesignTokens.textMuted : DesignTokens.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo upload placeholder
            _buildPhotoUpload(),
            const SizedBox(height: DesignTokens.sp6),

            // Basic info section
            _buildSectionTitle('基本資訊'),
            const SizedBox(height: DesignTokens.sp4),

            CBInput(
              label: '餐點名稱',
              controller: _nameController,
              hintText: '例如：招牌炒飯',
            ),
            const SizedBox(height: DesignTokens.sp4),

            CBInput(
              label: '說明',
              controller: _descController,
              hintText: '簡短描述餐點特色',
              maxLines: 3,
            ),
            const SizedBox(height: DesignTokens.sp4),

            CBInput(
              label: '售價 (NT\$)',
              controller: _priceController,
              keyboardType: TextInputType.number,
              hintText: '例如：80',
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Preparation section
            _buildSectionTitle('備餐資訊'),
            const SizedBox(height: DesignTokens.sp4),

            CBInput(
              label: '預設備餐時間（分鐘）',
              controller: _prepTimeController,
              keyboardType: TextInputType.number,
              hintText: '例如：15',
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Volume & Weight section
            _buildSectionTitle('容量 / 重量等級'),
            const SizedBox(height: DesignTokens.sp4),

            _buildLevelSelector(
              label: '體積等級',
              value: _volumeLevel,
              options: const ['V1', 'V2', 'V3', 'V4'],
              descriptions: const [
                'V1: 單份飯類',
                'V2: 標準餐盒',
                'V3: 多份或飲料組',
                'V4: 大鍋餐盒',
              ],
              onChanged: (value) => setState(() => _volumeLevel = value!),
            ),

            const SizedBox(height: DesignTokens.sp4),

            _buildLevelSelector(
              label: '重量等級',
              value: _weightLevel,
              options: const ['W1', 'W2', 'W3', 'W4'],
              descriptions: const [
                'W1: 輕量（<500g）',
                'W2: 標準（500g-1kg）',
                'W3: 偏重（1kg-2kg）',
                'W4: 重量（>2kg）',
              ],
              onChanged: (value) => setState(() => _weightLevel = value!),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Stock section
            _buildSectionTitle('庫存管理'),
            const SizedBox(height: DesignTokens.sp4),

            CBInput(
              label: '每日可售數',
              controller: _stockController,
              keyboardType: TextInputType.number,
              hintText: '例如：50',
            ),

            const SizedBox(height: DesignTokens.sp4),

            _buildSwitchRow(
              label: '售罄自動下架',
              value: _autoOffOnSoldOut,
              onChanged: (value) => setState(() => _autoOffOnSoldOut = value),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Availability section
            _buildSectionTitle('上架狀態'),
            const SizedBox(height: DesignTokens.sp4),

            _buildSwitchRow(
              label: '立即上架',
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Options/Add-ons placeholder
            _buildSectionTitle('選配 / 加購（開發中）'),
            const SizedBox(height: DesignTokens.sp4),

            CBCard(
              child: const Padding(
                padding: EdgeInsets.all(DesignTokens.sp4),
                child: Text(
                  '單選/多選、必選/可選、加價金額等功能開發中',
                  style: TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Save button
            CBButton(
              text: isEdit ? '儲存變更' : '新增餐點',
              onPressed: _isLoading ? null : _handleSave,
              isLoading: _isLoading,
              size: CBButtonSize.large,
            ),

            if (isEdit) ...[
              const SizedBox(height: DesignTokens.sp4),
              CBButton(
                text: '刪除餐點',
                onPressed: _handleDelete,
                type: CBButtonType.secondary,
                size: CBButtonSize.large,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return CBCard(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: DesignTokens.bgSubtle,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: DesignTokens.sp3),
            Text(
              '上傳餐點照片（開發中）',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: DesignTokens.fsLg,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textPrimary,
      ),
    );
  }

  Widget _buildLevelSelector({
    required String label,
    required String value,
    required List<String> options,
    required List<String> descriptions,
    required ValueChanged<String?> onChanged,
  }) {
    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: DesignTokens.fsMd,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp3),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final option = entry.value;
            return RadioListTile<String>(
              title: Text(
                descriptions[idx],
                style: const TextStyle(fontSize: DesignTokens.fsSm),
              ),
              value: option,
              groupValue: value,
              onChanged: onChanged,
              activeColor: DesignTokens.brand,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CBCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: DesignTokens.fsMd,
              color: DesignTokens.textPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: DesignTokens.brand,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      CBToast.show(
        context: context,
        message: '請輸入餐點名稱',
        type: CBToastType.error,
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      CBToast.show(
        context: context,
        message: '請輸入有效價格',
        type: CBToastType.error,
      );
      return;
    }

    final prepTime = int.tryParse(_prepTimeController.text);
    if (prepTime == null || prepTime <= 0) {
      CBToast.show(
        context: context,
        message: '請輸入有效備餐時間',
        type: CBToastType.error,
      );
      return;
    }

    final stock = int.tryParse(_stockController.text);
    if (stock == null || stock < 0) {
      CBToast.show(
        context: context,
        message: '請輸入有效庫存數量',
        type: CBToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final merchantId = authService.currentUserId!;
      final menuService = ref.read(menuServiceProvider);

      if (widget.item == null) {
        // 新增
        await menuService.createMenuItem(
          merchantId: merchantId,
          category: widget.category['name'],
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          price: price,
          volumeLevel: _volumeLevel,
          weightLevel: _weightLevel,
          prepTimeMinutes: prepTime,
          stockQuantity: stock,
        );
      } else {
        // 更新
        await menuService.updateMenuItem(
          itemId: widget.item!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          price: price,
          isAvailable: _isAvailable,
          volumeLevel: _volumeLevel,
          weightLevel: _weightLevel,
          prepTimeMinutes: prepTime,
          stockQuantity: stock,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        CBToast.show(
          context: context,
          message: widget.item == null ? '餐點已新增' : '餐點已更新',
          type: CBToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CBToast.show(
          context: context,
          message: '儲存失敗: $e',
          type: CBToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除餐點'),
        content: Text('確定要刪除「${_nameController.text}」嗎？'),
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

    if (confirm == true && mounted) {
      try {
        await ref.read(menuServiceProvider).deleteMenuItem(widget.item!.id);

        if (mounted) {
          Navigator.pop(context);
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
}
