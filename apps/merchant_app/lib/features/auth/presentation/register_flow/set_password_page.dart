import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:go_router/go_router.dart';

/// Set Password Page
/// [customer_app_whitepaper.md Section 1.1] Final step of registration
class SetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String phone;
  final String deviceId;

  const SetPasswordPage({
    super.key,
    required this.email,
    required this.phone,
    required this.deviceId,
  });

  @override
  ConsumerState<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends ConsumerState<SetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || password.length < 6) {
      setState(() => _errorMessage = '密碼至少需要6個字元');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = '密碼與確認密碼不符');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Sign up with email and password
      await authService.signUpWithEmail(
        email: widget.email,
        password: password,
      );

      // Sign in to get user ID
      await authService.signInWithEmail(
        email: widget.email,
        password: password,
      );

      final userId = authService.currentUserId;
      if (userId == null) {
        throw Exception('登入失敗');
      }

      // [Phase 1.2] Bind device to user
      final deviceService = ref.read(deviceServiceProvider);
      final bindResult = await deviceService.bindDeviceToUser(
        deviceId: widget.deviceId,
        userId: userId,
      );

      if (!bindResult.success && !bindResult.isDevMode) {
        throw Exception(bindResult.message ?? '裝置綁定失敗');
      }

      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '註冊成功',
          type: CBToastType.success,
        );

        // [merchant_app_whitepaper.md] 註冊完成直接登入，進入 CurrentOrders
        context.go('/current-orders');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
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
      appBar: AppBar(
        title: const Text('設定密碼'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              '設定您的密碼',
              style: TextStyle(
                fontSize: DesignTokens.fs2xl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),

            const SizedBox(height: DesignTokens.sp2),

            // Email/Phone summary
            Container(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              decoration: BoxDecoration(
                color: DesignTokens.bgSubtle,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: ${widget.email}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.sp1),
                  Text(
                    '手機: ${widget.phone}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Password input
            CBInput(
              label: '設定密碼',
              controller: _passwordController,
              obscureText: _obscurePassword,
              hintText: '至少6個字元',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: DesignTokens.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),

            const SizedBox(height: DesignTokens.sp4),

            // Confirm password input
            CBInput(
              label: '確認密碼',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              hintText: '再次輸入密碼',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: DesignTokens.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Register button
            CBButton(
              text: '註冊',
              onPressed: _isLoading ? null : _handleRegister,
              isLoading: _isLoading,
              size: CBButtonSize.large,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: DesignTokens.sp4),
              Container(
                padding: const EdgeInsets.all(DesignTokens.sp3),
                decoration: BoxDecoration(
                  color: DesignTokens.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

