import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/widgets/app_bottom_nav.dart';
import 'package:customer_app/features/account/presentation/notifications_page.dart';
import 'package:customer_app/features/account/presentation/addresses_page.dart';
import 'package:customer_app/features/account/presentation/settings_page.dart';
import 'package:customer_app/features/account/presentation/help_center_page.dart';

/// Account Page
/// [customer_app_whitepaper.md Section 6]
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('帳號'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User info card
            CBCard(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: DesignTokens.bgSubtle,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp4),
                  const Text(
                    '測試顧客', // TODO: Load from user_profiles.nickname
                    style: TextStyle(
                      fontSize: DesignTokens.fsXl,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp2),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Menu items
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: '通知',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: '地址管理',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddressesPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: '幫助中心',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: '設定',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Logout
            CBButton(
              text: '登出',
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              type: CBButtonType.secondary,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return CBCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.brand),
          const SizedBox(width: DesignTokens.sp4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textPrimary,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: DesignTokens.textMuted,
          ),
        ],
      ),
    );
  }
}
