import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';

/// Courier Account Page
/// [courier_app_whitepaper.md Section 6]
/// 姓名、Email、手機號碼、通知、驗證狀態、銀行帳戶、幫助中心、設定、登出
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
          // Profile
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.person_outline,
                  title: '姓名',
                  subtitle: 'TODO: 顯示真實姓名',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'TODO: 顯示 Email',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.phone_outlined,
                  title: '手機號碼',
                  subtitle: 'TODO: 顯示手機號碼',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Settings
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.notifications_outlined,
                  title: '通知',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.verified_user_outlined,
                  title: '驗證狀態',
                  subtitle: 'TODO: KYC 狀態',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.account_balance_outlined,
                  title: '銀行帳戶',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: '幫助中心',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.settings_outlined,
                  title: '設定',
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
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

