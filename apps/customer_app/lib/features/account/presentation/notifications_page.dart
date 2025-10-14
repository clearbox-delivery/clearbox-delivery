import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';

/// Notifications Settings Page
/// [customer_app_whitepaper.md Section 6]
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        children: [
          _buildToggleItem('訂單狀態更新', true),
          _buildToggleItem('外送員到達提醒', true),
          _buildToggleItem('優惠通知', false),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool value) {
    return CBCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: DesignTokens.fsMd,
              color: DesignTokens.textPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // TODO: Save preference
            },
            activeColor: DesignTokens.brand,
          ),
        ],
      ),
    );
  }
}

