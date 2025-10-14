import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';

/// Courier Order History Page
/// [courier_app_whitepaper.md Section 5]
/// Tabs: 今日、本週、全部 with metrics header
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('歷史訂單'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DesignTokens.textPrimary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorColor: DesignTokens.brand,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: '今日'),
            Tab(text: '本週'),
            Tab(text: '全部'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab('今日'),
          _buildTab('本週'),
          _buildTab('全部'),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTab(String period) {
    return Column(
      children: [
        // Metrics header - TODO: implement in Phase 4.4
        Container(
          padding: const EdgeInsets.all(DesignTokens.sp4),
          color: DesignTokens.bgSubtle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('上線時間', 'TODO'),
              _buildMetric('訂單數', 'TODO'),
              _buildMetric('收益', 'TODO'),
            ],
          ),
        ),
        const Expanded(
          child: CBEmptyState(
            icon: Icons.receipt_long_outlined,
            title: '尚無訂單',
            description: '完成的訂單會在此顯示',
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fsXs,
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp1),
        Text(
          value,
          style: const TextStyle(
            fontSize: DesignTokens.fsMd,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

