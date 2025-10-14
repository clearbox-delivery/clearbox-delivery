import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';

/// Merchant App Bottom Navigation
/// [merchant_app_whitepaper.md Section 3] Four tabs: CurrentOrders, OrderHistory, MenuManagement, Account
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DesignTokens.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: DesignTokens.brand,
        unselectedItemColor: DesignTokens.textSecondary,
        selectedFontSize: DesignTokens.fsXs,
        unselectedFontSize: DesignTokens.fsXs,
        type: BottomNavigationBarType.fixed,
        backgroundColor: DesignTokens.bg,
        elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/current-orders');
              break;
            case 1:
              context.go('/history');
              break;
            case 2:
              context.go('/menu');
              break;
            case 3:
              context.go('/account');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: '接單',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '歷史',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: '菜單',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '帳號',
          ),
        ],
      ),
    );
  }
}

