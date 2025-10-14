import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';

/// Courier Account Page
/// [courier_app_whitepaper.md Section 6]
/// [REQ-COU-ACC-001] Account settings and profile
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _isAcceptingOrders = true;
  bool _isPushEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('帳號'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        children: [
          // Profile Section
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.person_outline,
                  title: '個人資料',
                  subtitle: user?.email ?? 'courier@example.com',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '個人資料編輯功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.directions_bike_outlined,
                  title: '車輛資訊',
                  subtitle: '車牌號碼、車輛類型',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '車輛資訊編輯功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Work Status Section
          CBCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.work_outline,
                  title: '接受新訂單',
                  subtitle: _isAcceptingOrders ? '目前可接單' : '暫停接單',
                  value: _isAcceptingOrders,
                  onChanged: (value) {
                    setState(() => _isAcceptingOrders = value);
                    CBToast.show(
                      context: context,
                      message: value ? '已開始接單' : '已暫停接單',
                      type: CBToastType.success,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Notifications & Settings Section
          CBCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: '推播通知',
                  subtitle: _isPushEnabled ? '已啟用' : '已關閉',
                  value: _isPushEnabled,
                  onChanged: (value) {
                    setState(() => _isPushEnabled = value);
                    CBToast.show(
                      context: context,
                      message: value ? '已啟用推播通知' : '已關閉推播通知',
                      type: CBToastType.info,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.verified_user_outlined,
                  title: 'KYC 驗證狀態',
                  subtitle: '已完成（開發中）',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: 'KYC 流程開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.phone_android_outlined,
                  title: '裝置安全',
                  subtitle: '裝置綁定與驗證',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '裝置安全功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Financial Section
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.account_balance_outlined,
                  title: '銀行帳戶',
                  subtitle: '****** 1234',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '銀行帳戶管理功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: '合約與文件',
                  subtitle: '勞務契約、保險證明',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '合約文件功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Help & Support Section
          CBCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.help_outline,
                  title: '幫助中心',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '幫助中心功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.feedback_outlined,
                  title: '意見回饋',
                  onTap: () {
                    CBToast.show(
                      context: context,
                      message: '意見回饋功能開發中',
                      type: CBToastType.info,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: '關於',
                  subtitle: 'v1.0.0 (MVP)',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp4),

          // Logout Section
          CBCard(
            child: _buildListTile(
              icon: Icons.logout_outlined,
              title: '登出',
              textColor: DesignTokens.danger,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認登出'),
                    content: const Text('確定要登出嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          '登出',
                          style: TextStyle(color: DesignTokens.danger),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    CBToast.show(
                      context: context,
                      message: '已登出',
                      type: CBToastType.success,
                    );
                  }
                }
              },
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: DesignTokens.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: DesignTokens.fsMd,
          color: DesignTokens.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: DesignTokens.fsSm,
          color: DesignTokens.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: DesignTokens.brand,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp4,
        vertical: DesignTokens.sp2,
      ),
    );
  }
}
