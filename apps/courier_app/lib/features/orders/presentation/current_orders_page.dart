import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';
import 'package:courier_app/features/orders/flow/stage1_available_list_page.dart';

/// Courier Current Orders Page (Main hub)
/// [courier_app_whitepaper.md Section 4]
/// [REQ-COU-FLOW-001] Heat map + "我要接單" button + 4-stage flow
class CurrentOrdersPage extends ConsumerWidget {
  const CurrentOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Heat map placeholder
          Container(
            height: 200,
            margin: const EdgeInsets.all(DesignTokens.sp4),
            decoration: BoxDecoration(
              color: DesignTokens.bgSubtle,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: DesignTokens.border),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: DesignTokens.textMuted),
                  SizedBox(height: DesignTokens.sp3),
                  Text(
                    '需求熱度地圖（H3 熱圖開發中）',
                    style: TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
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

  void _startOrderFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Stage1AvailableListPage(),
      ),
    );
  }
}

