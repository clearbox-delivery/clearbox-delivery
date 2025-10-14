import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:geo_h3/geo_h3.dart';
import 'package:courier_app/features/orders/flow/stage2_go_merchant_page.dart';

/// Stage 1: Available Orders List with R/T sorting
/// [courier_app_whitepaper.md Section 4.2 進度1]
/// [REQ-COU-FLOW-001] Show WAITING_COURIER orders, sorted by R/T
class Stage1AvailableListPage extends ConsumerStatefulWidget {
  const Stage1AvailableListPage({super.key});

  @override
  ConsumerState<Stage1AvailableListPage> createState() => _Stage1AvailableListPageState();
}

class _Stage1AvailableListPageState extends ConsumerState<Stage1AvailableListPage> {
  String? _courierH3;
  final Map<String, int?> _etaCache = {}; // Simple in-memory cache

  @override
  void initState() {
    super.initState();
    _initCourierH3();
  }

  Future<void> _initCourierH3() async {
    try {
      final position = await GPSService.getCurrentPosition();
      final h3 = H3Service.toH3Res10(position);
      if (mounted) {
        setState(() => _courierH3 = h3);
      }
    } catch (e) {
      // GPS not available, keep null (will show all orders)
      if (mounted) {
        setState(() => _courierH3 = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final courierId = authService.currentUserId;

    if (courierId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    // Use Realtime stream for available orders
    // H3 filtering: backend doesn't filter by h3Cell yet, will filter client-side
    final ordersStream = ref.watch(realtimeServiceProvider).watchAvailableOrders(
      h3Cell: null, // Backend filter not implemented yet
    );

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('可接訂單'),
        subtitle: const Text(
          '依單位時間收益排序（R/T）',
          style: TextStyle(
            fontSize: DesignTokens.fsSm,
            color: DesignTokens.textSecondary,
          ),
        ),
      ),
      body: StreamBuilder<List<Order>>(
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

          final orders = snapshot.data ?? [];

          // Filter client-side for WAITING_COURIER
          var availableOrders = orders
              .where((o) => o.status == OrderStatus.waitingCourier)
              .toList();

          // H3 k=40 range filtering (client-side)
          if (_courierH3 != null) {
            availableOrders = availableOrders.where((o) {
              if (o.h3Merchant == null) return true; // Include if no H3 data
              return H3Service.isWithinDistance(_courierH3!, o.h3Merchant!, 40);
            }).toList();
          }

          if (availableOrders.isEmpty) {
            return CBEmptyState(
              icon: Icons.delivery_dining_outlined,
              title: '目前無可接訂單',
              description: _courierH3 != null
                  ? '附近 40 格範圍內暫無訂單'
                  : '附近訂單會即時顯示',
            );
          }

          // Sort by R/T with real distance data (async)
          return FutureBuilder<List<Order>>(
            future: _sortByRTWithRealETA(availableOrders),
            builder: (context, sortSnapshot) {
              final sortedOrders = sortSnapshot.data ?? availableOrders;

              return ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.sp4),
                itemCount: sortedOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
                itemBuilder: (context, index) {
                  final order = sortedOrders[index];
                  return _AvailableOrderCard(
                    key: Key('courier-available-${order.id}'),
                    order: order,
                    onAccept: () => _handleAcceptOrder(context, ref, order),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Fetch real ETA data and sort by R/T
  /// [REQ-COU-FLOW-004] Enable real OSRM distance data
  /// [REQ-COU-FLOW-005] Batch queries with de-duplication
  /// Strategy: Batch query all unique H3 pairs, cache results, graceful fallback
  Future<List<Order>> _sortByRTWithRealETA(List<Order> orders) async {
    if (orders.isEmpty) return orders;

    final distanceService = ref.read(distanceServiceProvider);
    final courierToMerchantEtas = <String, int?>{};
    final merchantToCustomerEtas = <String, int?>{};

    // Collect all unique H3 pairs (de-duplication)
    final pairs = <({String from, String to})>[];
    final seenPairs = <String>{};

    for (final order in orders) {
      if (order.h3Merchant == null || order.h3Customer == null) continue;

      // Courier → Merchant
      if (_courierH3 != null) {
        final key = '${_courierH3!}->${order.h3Merchant!}';
        if (!seenPairs.contains(key)) {
          pairs.add((from: _courierH3!, to: order.h3Merchant!));
          seenPairs.add(key);
        }
      }

      // Merchant → Customer
      final key2 = '${order.h3Merchant!}->${order.h3Customer!}';
      if (!seenPairs.contains(key2)) {
        pairs.add((from: order.h3Merchant!, to: order.h3Customer!));
        seenPairs.add(key2);
      }
    }

    // Batch query all pairs
    final etaMap = await distanceService.getBatchETA(pairs: pairs);

    // Map ETAs to orders
    for (final order in orders) {
      if (order.h3Merchant == null || order.h3Customer == null) continue;

      if (_courierH3 != null) {
        final key = '${_courierH3!}->${order.h3Merchant!}';
        courierToMerchantEtas[order.merchantId] = etaMap[key];
      }

      final key2 = '${order.h3Merchant!}->${order.h3Customer!}';
      merchantToCustomerEtas[order.id] = etaMap[key2];
    }

    // Sort with real ETAs (will use fallback if null)
    return RTCalculator.sortByRT(
      orders: orders,
      courierToMerchantEtas: courierToMerchantEtas,
      merchantToCustomerEtas: merchantToCustomerEtas,
    );
  }

  Future<void> _handleAcceptOrder(BuildContext context, WidgetRef ref, Order order) async {
    try {
      final result = await ref.read(orderServiceProvider).acceptOrder(order.id);

      if (!result.success) {
        if (context.mounted) {
          CBToast.show(
            context: context,
            message: result.message ?? '接單失敗',
            type: CBToastType.error,
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Stage2GoMerchantPage(order: order),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CBToast.show(
          context: context,
          message: '接單失敗: $e',
          type: CBToastType.error,
        );
      }
    }
  }
}

class _AvailableOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;

  const _AvailableOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final mealPrice = order.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    return CBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and delivery fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '訂單 ${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.sp3,
                  vertical: DesignTokens.sp2,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  'NT\$${order.deliveryPriceUserSet.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.brand,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Distance and ETA placeholder
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              const Text(
                '距離 1.5km',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(Icons.timer_outlined, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp2),
              Text(
                '預估 ${order.prepTimeMinutes ?? 15} 分',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sp3),

          // Items summary
          Text(
            '${order.items.length} 項餐點 • NT\$${mealPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Accept button
          CBButton(
            text: '接受訂單',
            onPressed: onAccept,
            size: CBButtonSize.medium,
          ),
        ],
      ),
    );
  }
}
