import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:courier_app/features/orders/flow/stage3_wait_merchant_page.dart';

/// Stage 2: Go to Merchant (前往店家)
/// [courier_app_whitepaper.md Section 4.2 進度2]
/// [REQ-COU-FLOW-002] Navigate to merchant, arrival photo placeholder
class Stage2GoMerchantPage extends ConsumerWidget {
  final Order order;

  const Stage2GoMerchantPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('前往店家'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Delivery icon
            const Icon(
              Icons.store_outlined,
              size: 80,
              color: DesignTokens.brand,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Merchant info placeholder
            Text(
              '請前往店家取餐',
              style: const TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp4),

            const Text(
              '店家地址（待整合 merchant_profiles）',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Distance and ETA placeholder
            Container(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              decoration: BoxDecoration(
                color: DesignTokens.bgSubtle,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: DesignTokens.brand),
                      SizedBox(width: DesignTokens.sp2),
                      Text(
                        '距離 1.5km',
                        style: TextStyle(
                          fontSize: DesignTokens.fsMd,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.sp2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: DesignTokens.brand),
                      SizedBox(width: DesignTokens.sp2),
                      Text(
                        'ETA 5 分鐘',
                        style: TextStyle(
                          fontSize: DesignTokens.fsMd,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.sp8),

            // Google Maps link placeholder
            CBButton(
              text: '開啟 Google Maps 導航',
              onPressed: () {
                CBToast.show(
                  context: context,
                  message: 'Google Maps 導航開發中',
                  type: CBToastType.info,
                );
              },
              variant: CBButtonVariant.secondary,
              size: CBButtonSize.large,
              icon: Icons.map_outlined,
            ),

            const SizedBox(height: DesignTokens.sp4),

            // Arrived button
            CBButton(
              text: '我已抵達',
              onPressed: () => _handleArrived(context),
              size: CBButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  void _handleArrived(BuildContext context) {
    // TODO: Implement photo capture for arrival proof
    CBToast.show(
      context: context,
      message: '到店拍照功能開發中（直接進入等待備餐）',
      type: CBToastType.info,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Stage3WaitMerchantPage(order: order),
      ),
    );
  }
}

