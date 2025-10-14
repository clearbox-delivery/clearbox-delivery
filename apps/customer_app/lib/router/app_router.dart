import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/features/auth/presentation/login_page.dart';
import 'package:customer_app/features/orders/presentation/new_order_page.dart';
import 'package:customer_app/features/orders/presentation/order_history_page.dart';
import 'package:customer_app/features/account/presentation/account_page.dart';

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
        return '/new-order';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/new-order',
        builder: (context, state) => const NewOrderPage(),
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


