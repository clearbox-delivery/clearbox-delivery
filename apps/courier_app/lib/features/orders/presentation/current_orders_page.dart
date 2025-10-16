import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:geo_h3/geo_h3.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';
import 'package:courier_app/features/orders/flow/stage1_available_list_page.dart';
import 'package:courier_app/features/heat/presentation/heat_map_widget.dart';

/// Courier Current Orders Page (Main hub)
/// [courier_app_whitepaper.md Section 4]
/// [REQ-COU-FLOW-001] Heat map + "我要接單" button + 4-stage flow
class CurrentOrdersPage extends ConsumerStatefulWidget {
  const CurrentOrdersPage({super.key});

  @override
  ConsumerState<CurrentOrdersPage> createState() => _CurrentOrdersPageState();
}

class _CurrentOrdersPageState extends ConsumerState<CurrentOrdersPage> {
  String? _courierH3;

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

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('接單'),
      ),
      body: Column(
        children: [
          // Heat map widget
          Padding(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            child: HeatMapWidget(
              centerH3: _courierH3,
              heatValues: _getMockHeatData(),
              k: 40,
              onCellTap: (h3Cell) => _showCellStats(context, h3Cell),
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // "我要接單" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.sp6),
            child: CBButton(
              text: '我要接單',
              onPressed: () => _startOrderFlow(context),
              size: CBButtonSize.large,
              icon: Icons.delivery_dining,
            ),
          ),

          const SizedBox(height: DesignTokens.sp6),

          // Status or instructions
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.sp6),
            child: Text(
              '點擊「我要接單」開始接單流程',
              style: TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Map<String, double> _getMockHeatData() {
    // TODO: Fetch real heat data from backend
    // For now, return mock data (center highest, gradually decreasing)
    if (_courierH3 == null) return {};

    return {
      _courierH3!: 0.9,
      // Mock surrounding cells with lower heat
      '${_courierH3!}-n': 0.6,
      '${_courierH3!}-s': 0.6,
      '${_courierH3!}-e': 0.6,
      '${_courierH3!}-w': 0.6,
    };
  }

  void _startOrderFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Stage1AvailableListPage(),
      ),
    );
  }

  void _showCellStats(BuildContext context, String h3Cell) {
    // Mock data for demonstration
    // TODO: Fetch real stats from backend
    final waitingOrders = _courierH3 != null && h3Cell.contains(_courierH3!) ? 8 : 3;
    final activeCouriers = _courierH3 != null && h3Cell.contains(_courierH3!) ? 2 : 1;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        decoration: const BoxDecoration(
          color: DesignTokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '區域統計',
              style: TextStyle(
                fontSize: DesignTokens.fsLg,
                fontWeight: FontWeight.bold,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.sp2),
            Text(
              'H3 Cell: $h3Cell',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.sp3),
            _buildStatRow('等待訂單', waitingOrders.toString(), Icons.shopping_bag),
            const SizedBox(height: DesignTokens.sp2),
            _buildStatRow('活躍外送員', activeCouriers.toString(), Icons.delivery_dining),
            const SizedBox(height: DesignTokens.sp3),
            CBButton(
              text: '關閉',
              onPressed: () => Navigator.of(context).pop(),
              type: CBButtonType.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DesignTokens.textSecondary),
        const SizedBox(width: DesignTokens.sp2),
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fsMd,
            color: DesignTokens.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}


