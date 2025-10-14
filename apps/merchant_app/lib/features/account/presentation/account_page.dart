import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/widgets/app_bottom_nav.dart';

/// Merchant Account Page
/// [merchant_app_whitepaper.md Section 8]
/// [REQ-MER-ACC-001] Store profile, business operations, notifications, financial docs, support
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _isOperating = true; // 營業中/休息中
  bool _acceptingOrders = true; // 接單開關

  @override
  Widget build(BuildContext context) {
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
                  onTap: _handleStoreBasicInfo,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.verified_outlined,
                  title: '驗證狀態',
                  subtitle: '食品業者登錄、營業登記',
                  onTap: _handleVerificationStatus,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.preview_outlined,
                  title: '顧客端預覽',
                  subtitle: '查看店鋪在顧客端的呈現',
                  onTap: _handleCustomerPreview,
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
                _buildSwitchTile(
                  icon: Icons.store,
                  title: '營業狀態',
                  subtitle: _isOperating ? '營業中' : '休息中',
                  value: _isOperating,
                  onChanged: (value) {
                    setState(() => _isOperating = value);
                    CBToast.show(
                      context: context,
                      message: value ? '已切換為營業中' : '已切換為休息中',
                      type: CBToastType.success,
                    );
                  },
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildSwitchTile(
                  icon: Icons.delivery_dining,
                  title: '接受外送訂單',
                  subtitle: _acceptingOrders ? '目前接單中' : '已暫停接單',
                  value: _acceptingOrders,
                  onChanged: (value) {
                    setState(() => _acceptingOrders = value);
                    CBToast.show(
                      context: context,
                      message: value ? '已恢復接單' : '已暫停接單',
                      type: CBToastType.success,
                    );
                  },
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.schedule_outlined,
                  title: '營業時間設定',
                  subtitle: '設定每日營業時段',
                  onTap: _handleBusinessHours,
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
                  subtitle: '新單、接單、到店、送達提醒',
                  onTap: _handleNotificationSettings,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.devices_outlined,
                  title: '裝置安全',
                  subtitle: '裝置綁定、最近登入紀錄',
                  onTap: _handleDeviceSecurity,
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
                  subtitle: '銀行帳戶資訊（遮罩）',
                  onTap: _handleBankAccount,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: '文件管理',
                  subtitle: '營業登記、食安字號',
                  onTap: _handleDocuments,
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
                  title: '常見問題',
                  onTap: _handleFAQ,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.support_agent_outlined,
                  title: '聯絡客服',
                  onTap: _handleContactSupport,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.feedback_outlined,
                  title: '問題回報',
                  onTap: _handleFeedback,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: '系統資訊',
                  subtitle: 'v1.0.0 (MVP)',
                  onTap: _handleSystemInfo,
                ),
                const Divider(height: 1, color: DesignTokens.border),
                _buildListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: '清除快取',
                  onTap: _handleClearCache,
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.sp6),

          // Logout
          CBButton(
            text: '登出',
            onPressed: _handleLogout,
            variant: CBButtonVariant.secondary,
            size: CBButtonSize.large,
            icon: Icons.logout_outlined,
          ),

          const SizedBox(height: DesignTokens.sp4),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            )
          : null,
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

  // Section 8.1 handlers
  void _handleStoreBasicInfo() {
    CBToast.show(
      context: context,
      message: '店家基本資料編輯功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleVerificationStatus() {
    CBToast.show(
      context: context,
      message: '驗證狀態查看功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleCustomerPreview() {
    CBToast.show(
      context: context,
      message: '顧客端預覽功能開發中',
      type: CBToastType.info,
    );
  }

  // Section 8.2 handlers
  void _handleBusinessHours() {
    CBToast.show(
      context: context,
      message: '營業時間設定功能開發中',
      type: CBToastType.info,
    );
  }

  // Section 8.3 handlers
  void _handleNotificationSettings() {
    CBToast.show(
      context: context,
      message: '推播通知設定功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleDeviceSecurity() {
    CBToast.show(
      context: context,
      message: '裝置安全管理功能開發中',
      type: CBToastType.info,
    );
  }

  // Section 8.4 handlers
  void _handleBankAccount() {
    CBToast.show(
      context: context,
      message: '收款帳戶管理功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleDocuments() {
    CBToast.show(
      context: context,
      message: '文件管理功能開發中',
      type: CBToastType.info,
    );
  }

  // Section 8.5 handlers
  void _handleFAQ() {
    CBToast.show(
      context: context,
      message: '常見問題頁面開發中',
      type: CBToastType.info,
    );
  }

  void _handleContactSupport() {
    CBToast.show(
      context: context,
      message: '聯絡客服功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleFeedback() {
    CBToast.show(
      context: context,
      message: '問題回報功能開發中',
      type: CBToastType.info,
    );
  }

  void _handleSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('系統資訊'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App 版本: 1.0.0 (MVP)'),
            SizedBox(height: DesignTokens.sp2),
            Text('建置日期: 2025-01-15'),
            SizedBox(height: DesignTokens.sp2),
            Text('環境: Development'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _handleClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除快取'),
        content: const Text('確定要清除本地快取嗎？這將清除暫存的圖片與資料。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              CBToast.show(
                context: context,
                message: '快取已清除',
                type: CBToastType.success,
              );
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  CBToast.show(
                    context: context,
                    message: '已登出',
                    type: CBToastType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  CBToast.show(
                    context: context,
                    message: '登出失敗: $e',
                    type: CBToastType.error,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.danger),
            child: const Text('登出'),
          ),
        ],
      ),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            )
          : null,
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
