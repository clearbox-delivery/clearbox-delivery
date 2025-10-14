import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:merchant_app/widgets/app_bottom_nav.dart';

/// Merchant Order History Page
/// [merchant_app_whitepaper.md Section 5]
/// 時間範圍、狀態篩選、搜尋、匯出CSV、訂單詳情
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('歷史訂單'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              // TODO: implement search in Phase 3.5
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // TODO: implement CSV export in Phase 3.5
            },
          ),
        ],
      ),
      body: const CBEmptyState(
        icon: Icons.receipt_long_outlined,
        title: '尚無歷史訂單',
        description: '完成的訂單會在此顯示',
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

