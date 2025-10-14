import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/features/auth/presentation/login_page.dart';
import 'package:courier_app/features/orders/presentation/available_orders_page.dart';
import 'package:courier_app/features/history/presentation/order_history_page.dart';
import 'package:courier_app/features/account/presentation/account_page.dart';

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
        builder: (context, state) => const AvailableOrdersPage(),
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


