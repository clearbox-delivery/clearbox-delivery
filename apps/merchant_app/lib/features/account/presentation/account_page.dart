import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:merchant_app/widgets/app_bottom_nav.dart';

/// Merchant Account Page
/// [merchant_app_whitepaper.md Section 8]
/// 8.1 店家資料, 8.2 營業與接單, 8.3 通知與裝置, 8.4 金融與文件, 8.5 其他
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('帳號'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        children: [
          // 8.1 店家資料
          _buildSectionTitle('店家資料'),
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.store_outlined,
                  title: '基本資料',
                  subtitle: '店名、地址、營業時間',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.verified_outlined,
                  title: '驗證狀態',
                  subtitle: '食品業者登錄、營業登記',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp6),

          // 8.2 營業與接單
          _buildSectionTitle('營業與接單'),
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.toggle_on_outlined,
                  title: '營業狀態',
                  subtitle: 'TODO: 營業中/休息中',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.pause_circle_outline,
                  title: '暫停接單',
                  subtitle: 'TODO: 設定暫停時段',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp6),

          // 8.3 通知與裝置
          _buildSectionTitle('通知與裝置'),
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.notifications_outlined,
                  title: '推播通知',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.devices_outlined,
                  title: '裝置安全',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp6),

          // 8.4 金融與文件
          _buildSectionTitle('金融與文件'),
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.account_balance_outlined,
                  title: '收款帳戶',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: '文件管理',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp6),

          // 8.5 其他
          _buildSectionTitle('其他'),
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.help_outline,
                  title: '客服與回饋',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: '系統資訊',
                  subtitle: 'App 版本、更新日誌',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Logout
          CBCard(
            child: _buildListTile(
              icon: Icons.logout_outlined,
              title: '登出',
              textColor: DesignTokens.danger,
              onTap: () {},
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: DesignTokens.sp2,
        bottom: DesignTokens.sp2,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: DesignTokens.fsSm,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textSecondary,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? DesignTokens.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: DesignTokens.fsMd,
          color: textColor ?? DesignTokens.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp4,
        vertical: DesignTokens.sp2,
      ),
    );
  }
}

