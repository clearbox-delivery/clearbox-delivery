import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/features/orders/presentation/adjust_prep_time_dialog.dart';
import 'package:merchant_app/features/orders/presentation/cancel_order_dialog.dart';
import 'dart:async';

/// Waiting Courier Tab
/// [merchant_app_whitepaper.md Section 4.2]
/// [REQ-MER-CO-002] Orders waiting for courier acceptance
class WaitingCourierTab extends ConsumerWidget {
  const WaitingCourierTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final merchantId = authService.currentUserId;

    if (merchantId == null) {
      return const Center(child: Text('Please login'));
    }

    final ordersStream = ref.watch(realtimeServiceProvider).watchMerchantOrders(merchantId);

    return StreamBuilder<List<Order>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CBLoadingIndicator());
        }

        if (snapshot.hasError) {
          return CBErrorState(
            title: '載入失敗',
            description: snapshot.error.toString(),
          );
        }

        final allOrders = snapshot.data ?? [];

        // Filter client-side for WAITING_COURIER
        final waitingOrders = allOrders
            .where((o) => o.status == OrderStatus.waitingCourier)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (waitingOrders.isEmpty) {
          return const CBEmptyState(
            icon: Icons.delivery_dining_outlined,
            title: '暫無待接單訂單',
            description: '確認的訂單會進入媒合',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          itemCount: waitingOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp4),
          itemBuilder: (context, index) {
            final order = waitingOrders[index];
            return _WaitingCourierCard(order: order);
          },
        );
      },
    );
  }
}

class _WaitingCourierCard extends ConsumerStatefulWidget {
  final Order order;

  const _WaitingCourierCard({required this.order});

  @override
  ConsumerState<_WaitingCourierCard> createState() => _WaitingCourierCardState();
}

class _WaitingCourierCardState extends ConsumerState<_WaitingCourierCard> {
  Timer? _countdownTimer;
  int _remainingSeconds = 600; // 10 minutes default

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealPrice = widget.order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '訂單 ${widget.order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsLg,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.sp2,
                  vertical: DesignTokens.sp1,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.warn.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  '等待中 ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.warn,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Match progress (mock data for MVP)
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              Text(
                '附近外送員: 8 人', // TODO: Real data
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(Icons.visibility_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              Text(
                '已曝光: 12 次', // TODO: Real data
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Estimated acceptance probability
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: DesignTokens.accent),
              const SizedBox(width: DesignTokens.sp2),
              Text(
                '預估接單機率: 75%', // TODO: Calculate from delivery fee + distance
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Pricing
          Row(
            children: [
              Text(
                '餐費 NT\$${mealPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              Text(
                '外送費 NT\$${widget.order.deliveryPriceUserSet.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Prep time
          if (widget.order.prepTimeMinutes != null)
            Text(
              '備餐時間: ${widget.order.prepTimeMinutes} 分鐘',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            ),

          const SizedBox(height: DesignTokens.sp4),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: CBButton(
                  text: '調整備餐時間',
                  onPressed: () => _showAdjustPrepTimeDialog(context, ref),
                  icon: Icons.edit_outlined,
                  variant: CBButtonVariant.secondary,
                  size: CBButtonSize.small,
                ),
              ),
              const SizedBox(width: DesignTokens.sp3),
              Expanded(
                child: CBButton(
                  text: '取消訂單',
                  onPressed: () => _showCancelDialog(context, ref),
                  variant: CBButtonVariant.secondary,
                  size: CBButtonSize.small,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp2),

          CBButton(
            text: '查看詳情',
            onPressed: () => _showDetails(context),
            variant: CBButtonVariant.secondary,
            size: CBButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _showAdjustPrepTimeDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => AdjustPrepTimeDialog(order: widget.order),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => CancelOrderDialog(order: widget.order),
    );
  }

  void _showDetails(BuildContext context) {
    // TODO: Show details sheet with route/fee distribution
    CBToast.show(
      context: context,
      message: '詳情功能開發中',
      type: CBToastType.info,
    );
  }
}

