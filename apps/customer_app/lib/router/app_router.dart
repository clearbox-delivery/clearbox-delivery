import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/features/auth/presentation/login_page.dart';
import 'package:customer_app/features/profile/presentation/initial_data_page.dart';
import 'package:customer_app/features/address/presentation/select_address_gate.dart';
import 'package:customer_app/features/orders/presentation/new_order_page.dart';
import 'package:customer_app/features/orders/presentation/order_history_page.dart';
import 'package:customer_app/features/account/presentation/account_page.dart';

/// Check if user has completed initial setup
/// [customer_app_whitepaper.md Section 2]
final hasCompletedInitialSetupProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;

  try {
    final response = await ref
        .read(supabaseProvider)
        .from('user_profiles')
        .select('initial_setup_complete')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return false;
    return (response as Map<String, dynamic>)['initial_setup_complete'] == true;
  } catch (e) {
    return false;
  }
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isInitialDataRoute = state.matchedLocation == '/initial-data';
      final isAddressGateRoute = state.matchedLocation == '/address-gate';

      // Not logged in -> force login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // Logged in but on login page -> proceed to flow
      if (isLoggedIn && isLoginRoute) {
        // Check if initial setup complete
        final setupComplete =
            await ref.read(hasCompletedInitialSetupProvider.future);

        if (!setupComplete) {
          return '/initial-data';
        }

        // Setup complete -> go to address gate
        return '/address-gate';
      }

      // Logged in, check flow gates
      if (isLoggedIn && !isInitialDataRoute && !isAddressGateRoute) {
        final setupComplete =
            await ref.read(hasCompletedInitialSetupProvider.future);

        if (!setupComplete) {
          return '/initial-data';
        }

        // Setup complete but need to select address each time
        // Skip gate redirect if already on main content (avoid loop)
        final mainRoutes = ['/new-order', '/history', '/account'];
        if (!mainRoutes.contains(state.matchedLocation)) {
          return '/address-gate';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/initial-data',
        builder: (context, state) => const InitialDataPage(),
      ),
      GoRoute(
        path: '/address-gate',
        builder: (context, state) => const SelectAddressGate(),
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
