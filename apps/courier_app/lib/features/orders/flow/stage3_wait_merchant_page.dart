import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:courier_app/features/orders/flow/stage4_go_customer_page.dart';

/// Stage 3: Wait for Merchant to Prepare
/// [courier_app_whitepaper.md Section 4.2 進度3]
/// [REQ-COU-FLOW-003] Wait for prep ready, pickup code placeholder
class Stage3WaitMerchantPage extends ConsumerWidget {
  final Order order;

  const Stage3WaitMerchantPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Calculate promised pickup time
    final prepMinutes = order.prepTimeMinutes ?? 15;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('等待備餐'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cooking icon
            const Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: DesignTokens.brand,
            ),

            const SizedBox(height: DesignTokens.sp6),

            const Text(
              '店家正在備餐中',
              style: TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp4),

            Text(
              '預計備餐時間：$prepMinutes 分鐘',
              style: const TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Countdown placeholder
            Container(
              padding: const EdgeInsets.all(DesignTokens.sp6),
              decoration: BoxDecoration(
                color: DesignTokens.bgSubtle,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Text(
                '倒數計時（開發中）',
                style: const TextStyle(
                  fontSize: DesignTokens.fs2xl,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.brand,
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.sp8),

            // Contact merchant
            CBButton(
              text: '聯絡店家',
              onPressed: () {
                CBToast.show(
                  context: context,
                  message: '聯絡店家功能開發中（雙向遮罩保護）',
                  type: CBToastType.info,
                );
              },
              type: CBButtonType.secondary,
              size: CBButtonSize.large,
              icon: Icons.phone_outlined,
            ),

            const SizedBox(height: DesignTokens.sp4),

            // Ready to pickup (mock)
            CBButton(
              text: '店家已備好（模擬）',
              onPressed: () => _handlePickup(context),
              size: CBButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePickup(BuildContext context) {
    // TODO: Implement pickup code verification
    CBToast.show(
      context: context,
      message: '取餐碼驗證開發中（直接進入配送）',
      type: CBToastType.info,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Stage4GoCustomerPage(order: order),
      ),
    );
  }
}

