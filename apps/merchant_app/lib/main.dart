import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:core_ui/core_ui.dart';
import 'package:merchant_app/router/app_router.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await initializeSupabase(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(
    const ProviderScope(
      child: MerchantApp(),
    ),
  );
}

class MerchantApp extends ConsumerWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final deviceService = ref.watch(deviceServiceProvider);

    return MaterialApp.router(
      title: 'ClearBox - Merchant',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // [Phase 1.2] Dev mode banner
        if (deviceService.isDevMode && child != null) {
          return Column(
            children: [
              const DevModeBanner(),
              Expanded(child: child),
            ],
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}


