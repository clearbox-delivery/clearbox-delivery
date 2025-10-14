import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:merchant_app/features/auth/presentation/login_page.dart';
import 'package:merchant_app/features/orders/presentation/current_orders_page.dart';
import 'package:merchant_app/features/menu/presentation/menu_management_page.dart';
import 'package:merchant_app/features/menu/presentation/categories_page.dart';
import 'package:merchant_app/features/menu/presentation/items_page.dart';
import 'package:merchant_app/features/menu/presentation/edit_item_page.dart';
import 'package:merchant_app/features/history/presentation/order_history_page.dart';
import 'package:merchant_app/features/account/presentation/account_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/current-orders';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/current-orders',
        builder: (context, state) => const CurrentOrdersPage(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const CategoriesPage(),
        routes: [
          GoRoute(
            path: 'items',
            builder: (context, state) {
              final category = state.extra as Map<String, dynamic>;
              return ItemsPage(category: category);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return EditItemPage(
                    category: data['category'],
                    item: data['item'],
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const OrderHistoryPage(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountPage(),
      ),
    ],
  );
});
