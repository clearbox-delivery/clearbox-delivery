import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';

/// Customer App Bottom Navigation
/// [customer_app_whitepaper.md Section 3] Three tabs: NewOrder, OrderHistory, Account
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
        selectedFontSize: DesignTokens.fsSm,
        unselectedFontSize: DesignTokens.fsSm,
        type: BottomNavigationBarType.fixed,
        backgroundColor: DesignTokens.bg,
        elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/new-order');
              break;
            case 1:
              context.go('/history');
              break;
            case 2:
              context.go('/account');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: '點餐',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: '歷史訂單',
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

