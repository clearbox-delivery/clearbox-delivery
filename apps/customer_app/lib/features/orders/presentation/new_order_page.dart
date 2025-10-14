import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:core_data/core_data.dart';
import 'package:customer_app/features/merchants/presentation/merchant_list_page.dart';
import 'package:customer_app/features/discovery/presentation/categories_overlay.dart';
import 'package:customer_app/widgets/app_bottom_nav.dart';

/// 顾客下单页面
/// [REQ-CUST-ORDER-001] 顾客自订外送费 (30-5000)
/// [UI_GUIDELINES.md] 使用 Design Tokens
class NewOrderPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;

  const NewOrderPage({super.key, this.extra});

  @override
  ConsumerState<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends ConsumerState<NewOrderPage> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasAutoShownCategories = false;

  @override
  void initState() {
    super.initState();

    // Auto-show categories overlay if flagged
    // [customer_app_whitepaper.md Section 4.1] 預設顯示「今天想吃什麼？」
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoShownCategories &&
          widget.extra?['autoShowCategories'] == true) {
        _hasAutoShownCategories = true;
        _showCategoriesOverlay();
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOrder() async {
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);

    if (price == null) {
      setState(() => _errorMessage = '請輸入有效的金額');
      return;
    }

    // [REQ-CUST-ORDER-001] 价格验证
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

      // TODO: 实际应从店家选择页面获取
      const merchantId = '00000000-0000-0000-0000-000000000002';

      await orderService.createOrder(
        merchantId: merchantId,
        items: [
          const OrderItem(
            sku: 'bento-001',
            name: '招牌便當',
            quantity: 1,
            unitPrice: 100,
          ),
        ],
        deliveryPrice: price,
        customerNotes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('訂單已建立'),
            backgroundColor: DesignTokens.accent,
          ),
        );
        _priceController.clear();
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '建立訂單失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoriesOverlay() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: DesignTokens.overlayScrim,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const CategoriesOverlay();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('NewOrder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar style button - opens category overlay
            // [customer_app_whitepaper.md Section 4.1]
            GestureDetector(
              onTap: _showCategoriesOverlay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.sp4,
                  vertical: DesignTokens.sp3,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSubtle,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: DesignTokens.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: DesignTokens.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.sp3),
                    const Text(
                      '今天想吃什麼？',
                      style: TextStyle(
                        fontSize: DesignTokens.fsMd,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            const Divider(),

            const SizedBox(height: DesignTokens.sp6),

            // 选择商家按钮
            CBButton(
              text: '選擇商家',
              icon: Icons.store,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantListPage(),
                  ),
                );
              },
              size: CBButtonSize.large,
            ),

            const SizedBox(height: DesignTokens.sp6),

            const Divider(),

            const SizedBox(height: DesignTokens.sp6),

            // 快速下单 (MVP 简化版)
            const Text(
              '快速下單',
              style: TextStyle(
                fontSize: DesignTokens.fsLg,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),

            const SizedBox(height: DesignTokens.sp4),

            // 价格输入
            CBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '設定外送費',
                    style: TextStyle(
                      fontSize: DesignTokens.fsMd,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp2),
                  Text(
                    '最低 NT\$${PriceValidator.minDeliveryPrice.toInt()}，'
                    '最高 NT\$${PriceValidator.maxDeliveryPrice.toInt()}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp4),
                  CBInput(
                    controller: _priceController,
                    hintText: '輸入金額',
                    keyboardType: TextInputType.number,
                    errorText: _errorMessage,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(DesignTokens.sp3),
                      child: Text(
                        'NT\$',
                        style: TextStyle(
                          fontSize: DesignTokens.fsMd,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // 备注
            CBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '訂單備註',
                    style: TextStyle(
                      fontSize: DesignTokens.fsLg,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp4),
                  CBInput(
                    controller: _notesController,
                    hintText: '例如：不要辣、過敏原等',
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.sp8),

            // 提交按钮
            CBButton(
              text: '建立訂單',
              onPressed: _isLoading ? null : _handleCreateOrder,
              isLoading: _isLoading,
              type: CBButtonType.primary,
              size: CBButtonSize.large,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
