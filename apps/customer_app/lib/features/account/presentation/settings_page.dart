import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';

/// Settings Page
/// [customer_app_whitepaper.md Section 6]
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.language,
            title: '語言',
            subtitle: '繁體中文',
            onTap: () {
              // TODO: Language settings
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.dark_mode_outlined,
            title: '主題',
            subtitle: '淺色',
            onTap: () {
              // TODO: Theme settings
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'App 版本',
            subtitle: '1.0.0',
            onTap: () {
              // TODO: Show changelog
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.delete_outline,
            title: '清除快取',
            onTap: () {
              // TODO: Clear cache
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DesignTokens.sp1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ],
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

