import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:domain/domain.dart';

/// 外送员可接订单页面
/// [REQ-COU-MATCH-003] 原子性接单
/// [REQ-COU-SORT-001] R/T 优先级排序
/// [UI_GUIDELINES.md] Design Tokens
class AvailableOrdersPage extends ConsumerWidget {
  const AvailableOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('可接訂單'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_availableOrdersProvider);
            },
          ),
        ],
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_availableOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const CBEmptyState(
            icon: Icons.delivery_dining_outlined,
            title: '目前沒有可接訂單',
            description: '有新訂單時會在此顯示',
          );
        }

        // [REQ-COU-SORT-001] R/T 优先级排序
        final sortedOrders = _sortByPriority(orders);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_availableOrdersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final orderPair = sortedOrders[index];
              return _OrderPriorityCard(
                order: orderPair.order,
                priority: orderPair.priority,
                onTap: () => _showAcceptDialog(context, ref, orderPair.order),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CBLoadingIndicator()),
      error: (error, stack) => CBErrorState(
        title: '載入失敗',
        description: error.toString(),
        actionLabel: '重試',
        onAction: () {
          ref.invalidate(_availableOrdersProvider);
        },
      ),
    );
  }

  /// [REQ-COU-SORT-001] R/T 优先级排序
  List<_OrderWithPriority> _sortByPriority(List<Order> orders) {
    final priorities = orders.map((order) {
      // MVP: 使用模拟数据
      final priority = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: order.deliveryPriceUserSet,
        travelTimeToMerchantMinutes: 10, // TODO: 实际计算
        prepTimeMinutes: order.prepTimeMinutes?.toDouble() ?? 15,
        deliveryTimeMinutes: 15, // TODO: 实际计算
      );

      return _OrderWithPriority(order: order, priority: priority);
    }).toList();

    priorities.sort((a, b) => b.priority.compareTo(a.priority));
    return priorities;
  }

  void _showAcceptDialog(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (context) => _AcceptOrderDialog(order: order),
    );
  }
}

class _OrderWithPriority {
  final Order order;
  final double priority;

  _OrderWithPriority({required this.order, required this.priority});
}

class _OrderPriorityCard extends StatelessWidget {
  final Order order;
  final double priority;
  final VoidCallback onTap;

  const _OrderPriorityCard({
    required this.order,
    required this.priority,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CBCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '訂單 #${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.sp3,
                  vertical: DesignTokens.sp1,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  '優先級 ${priority.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsXs,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.brand,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.sp3),
          
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                size: 16,
                color: DesignTokens.textSecondary,
              ),
              const SizedBox(width: DesignTokens.sp1),
              Text(
                'NT\$${order.deliveryPriceUserSet}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: DesignTokens.textSecondary,
              ),
              const SizedBox(width: DesignTokens.sp1),
              Text(
                '${order.prepTimeMinutes ?? 15} 分鐘',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.sp2),
          
          Text(
            '${order.items.length} 項商品',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const _AcceptOrderDialog({required this.order});

  @override
  ConsumerState<_AcceptOrderDialog> createState() => _AcceptOrderDialogState();
}

class _AcceptOrderDialogState extends ConsumerState<_AcceptOrderDialog> {
  bool _isLoading = false;

  /// [REQ-COU-MATCH-003] 原子性接单
  Future<void> _acceptOrder() async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final result = await orderService.acceptOrder(widget.order.id);

      if (!result.success) {
        // [TC-COU-ACPT-001] 处理冲突
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '訂單已被其他人接走'),
              backgroundColor: DesignTokens.warn,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('接單成功'),
            backgroundColor: DesignTokens.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('接單失敗: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      title: const Text(
        '確認接單',
        style: TextStyle(
          fontSize: DesignTokens.fsXl,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('訂單編號', widget.order.id.substring(0, 8)),
          const SizedBox(height: DesignTokens.sp2),
          _buildInfoRow('外送費', 'NT\$${widget.order.deliveryPriceUserSet}'),
          const SizedBox(height: DesignTokens.sp2),
          _buildInfoRow('商品數量', '${widget.order.items.length}'),
          if (widget.order.prepTimeMinutes != null) ...[
            const SizedBox(height: DesignTokens.sp2),
            _buildInfoRow('準備時間', '${widget.order.prepTimeMinutes} 分鐘'),
          ],
        ],
      ),
      actions: [
        CBButton(
          text: '取消',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          type: CBButtonType.secondary,
        ),
        CBButton(
          text: '確認接單',
          onPressed: _isLoading ? null : _acceptOrder,
          isLoading: _isLoading,
          type: CBButtonType.primary,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: DesignTokens.fsSm,
            color: DesignTokens.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: DesignTokens.fsSm,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Provider for available orders
final _availableOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getAvailableOrders();
});
