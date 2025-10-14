import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/widgets/app_bottom_nav.dart';
import 'package:merchant_app/features/orders/presentation/pending_confirm_tab.dart';
import 'package:merchant_app/features/orders/presentation/waiting_courier_tab.dart';
import 'package:go_router/go_router.dart';

/// 商家当前订单页面 - 4个标签页
/// [REQ-MER-CO-001] 商家确认订单 → WAITING_COURIER
/// [REQ-MER-CO-002] 2秒内实时更新
/// [UI_GUIDELINES.md] Tabs 底线式，Design Tokens
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
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('當前訂單'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DesignTokens.textPrimary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorColor: DesignTokens.brand,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: '待確認'),
            Tab(text: '待接單'),
            Tab(text: '準備中'),
            Tab(text: '待取貨'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const PendingConfirmTab(),
          const WaitingCourierTab(),
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DesignTokens.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: DesignTokens.brand,
        unselectedItemColor: DesignTokens.textSecondary,
        onTap: (index) {
          if (index == 1) {
            context.go('/menu');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: '當前訂單',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: '菜單管理',
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
    // [REQ-MER-CO-002] 实时更新
    final ordersStream = ref.watch(merchantOrdersStreamProvider(
      MerchantOrdersQuery(merchantId: merchantId, status: status),
    ));

    return ordersStream.when(
      data: (orders) {
        if (orders.isEmpty) {
          return CBEmptyState(
            icon: Icons.receipt_long_outlined,
            title: '目前沒有訂單',
            description: status == OrderStatus.pendingStoreConfirm
                ? '新訂單會在此顯示'
                : null,
          );
        }

        // [REQ-MER-CO-002] SafeListAnimation 防误触
        return SafeOrderList(
          orders: orders,
          itemBuilder: (order) {
            final isNew = _isNewOrder(order);
            return OrderCard(
              key: Key('order-card-${order.id}'),
              order: order,
              showHighlight: isNew,
              onTap: () => _showOrderDetail(context, ref, order),
            );
          },
        );
      },
      loading: () => const Center(
        child: CBLoadingIndicator(),
      ),
      error: (error, stack) => CBErrorState(
        title: '載入失敗',
        description: error.toString(),
        actionLabel: '重試',
        onAction: () {
          ref.invalidate(merchantOrdersStreamProvider);
        },
      ),
    );
  }

  /// [REQ-MER-CO-002] 新订单高亮 5 秒
  bool _isNewOrder(Order order) {
    final now = DateTime.now();
    final diff = now.difference(order.createdAt);
    return diff.inSeconds <= 5;
  }

  void _showOrderDetail(BuildContext context, WidgetRef ref, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  /// [REQ-MER-CO-001] 商家确认订单
  Future<void> _confirmOrder() async {
    final prepTime = int.tryParse(_prepTimeController.text);
    if (prepTime == null || prepTime <= 0) {
      _showError('請輸入有效的準備時間');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      await orderService.merchantConfirmOrder(
        orderId: widget.order.id,
        prepTimeMinutes: prepTime,
        merchantNotes: '已確認',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('訂單已確認'),
            backgroundColor: DesignTokens.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('確認失敗: $e');
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '訂單詳情',
                    style: TextStyle(
                      fontSize: DesignTokens.fsXl,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.sp4),

              // Order Info
              Text(
                '訂單編號: ${widget.order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),

              const SizedBox(height: DesignTokens.sp2),

              Text(
                '外送費: NT\$${widget.order.deliveryPriceUserSet}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),

              const SizedBox(height: DesignTokens.sp6),

              // Items
              const Text(
                '商品明細',
                style: TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),

              const SizedBox(height: DesignTokens.sp3),

              ...widget.order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.name} x ${item.quantity}',
                      style: const TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    Text(
                      'NT\$${item.unitPrice}',
                      style: const TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),

              if (widget.order.status == OrderStatus.pendingStoreConfirm) ...[
                const SizedBox(height: DesignTokens.sp6),

                CBInput(
                  label: '準備時間 (分鐘)',
                  controller: _prepTimeController,
                  keyboardType: TextInputType.number,
                  hintText: '例如: 15',
                ),

                const SizedBox(height: DesignTokens.sp6),

                CBButton(
                  text: '確認訂單',
                  onPressed: _isLoading ? null : _confirmOrder,
                  isLoading: _isLoading,
                  type: CBButtonType.primary,
                  size: CBButtonSize.large,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
