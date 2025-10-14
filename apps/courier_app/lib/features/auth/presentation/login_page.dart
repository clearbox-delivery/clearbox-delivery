import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/features/auth/presentation/register_flow/register_coordinator_page.dart';

/// Login page for courier with animation
/// [courier_app_whitepaper.md Section 1.0]
/// [REQ-COU-AUTH-001] Logo slide-up animation, email-only login
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
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.durationLong,
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveSmooth,
    ));

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: DesignTokens.curveSmooth),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
        context.go('/current-orders');
      }
    } catch (e) {
      if (mounted) {
        CBToast.show(
          context: context,
          message: '登入失敗: $e',
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
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.sp6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              SlideTransition(
                position: _logoSlideAnimation,
                child: const Icon(
                  Icons.delivery_dining,
                  size: 80,
                  color: DesignTokens.brand,
                ),
              ),

              const SizedBox(height: DesignTokens.sp8),

              // Fade-in Form
              FadeTransition(
                opacity: _formFadeAnimation,
                child: Column(
                  children: [
                    CBInput(
                      key: const Key('email'),
                      controller: _emailController,
                      label: 'Email',
                      hintText: '輸入您的 Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: DesignTokens.sp4),

                    CBInput(
                      controller: _passwordController,
                      label: '密碼',
                      hintText: '輸入您的密碼',
                      isPassword: true,
                    ),
                    const SizedBox(height: DesignTokens.sp6),

                    CBButton(
                      text: '登入',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      size: CBButtonSize.large,
                    ),
                    const SizedBox(height: DesignTokens.sp4),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterCoordinatorPage(),
                          ),
                        );
                      },
                      child: const Text(
                        '註冊',
                        style: TextStyle(color: DesignTokens.textSecondary),
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
