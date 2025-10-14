import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:core_ui/core_ui.dart';
import 'package:customer_app/features/auth/presentation/register_flow/register_coordinator_page.dart';

/// Login page for customer
/// [customer_app_whitepaper.md Section 1.0]
/// Logo center→slide up; inputs fade-in; respects reduced motion
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _inputsFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Check if reduced motion is enabled
    final reduceMotion =
        WidgetsBinding.instance.window.accessibilityFeatures.disableAnimations;

    _animationController = AnimationController(
      vsync: this,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 800), // Motion token: smooth
    );

    // Logo slides from center to top
    _logoSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.3),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic, // Motion token: natural curve
      ),
    );

    // Inputs fade in after logo starts moving
    _inputsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.3,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Start animation on first mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // [customer_app_whitepaper.md] Login -> NewOrder
        context.go('/new-order');
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '登入失敗: ${e.toString()}',
          type: CBToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.sp6,
            vertical: DesignTokens.sp8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              // Animated Logo - starts center, slides up
              SlideTransition(
                position: _logoSlideAnimation,
                child: const Icon(
                  Icons.delivery_dining,
                  size: 80,
                  color: DesignTokens.brand,
                ),
              ),

              const SizedBox(height: DesignTokens.sp8),

              // Inputs fade in after logo movement
              FadeTransition(
                opacity: _inputsFadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CBInput(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: '輸入 Email',
                    ),

                    const SizedBox(height: DesignTokens.sp4),

                    CBInput(
                      label: '密碼',
                      controller: _passwordController,
                      obscureText: true,
                      hintText: '輸入密碼',
                    ),

                    const SizedBox(height: DesignTokens.sp6),

                    CBButton(
                      text: '登入',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      size: CBButtonSize.large,
                    ),

                    const SizedBox(height: DesignTokens.sp4),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterCoordinatorPage(),
                            ),
                          );
                        },
                        child: const Text(
                          '註冊',
                          style: TextStyle(
                            fontSize: DesignTokens.fsSm,
                            color: DesignTokens.brand,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
