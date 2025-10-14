import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';

/// Help Center Page
/// [customer_app_whitepaper.md Section 6]
class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('幫助中心'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        children: [
          const Text(
            '常見問題',
            style: TextStyle(
              fontSize: DesignTokens.fsLg,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp4),
          _buildFAQItem(
            '如何下單？',
            '在 NewOrder 頁面輸入外送費金額並選擇商家即可下單',
          ),
          _buildFAQItem(
            '外送費範圍？',
            '最低 NT\$30，最高 NT\$5000',
          ),
          _buildFAQItem(
            '如何查看訂單狀態？',
            '在歷史訂單頁面可查看所有訂單記錄',
          ),

          const SizedBox(height: DesignTokens.sp8),

          // Contact support
          CBButton(
            text: '聯絡客服',
            onPressed: () {
              // TODO: Open support chat or link
            },
            icon: Icons.support_agent,
            variant: CBButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return CBCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: DesignTokens.fsMd,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp2),
          Text(
            answer,
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

