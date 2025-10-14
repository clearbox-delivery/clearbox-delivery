import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'dart:async';

/// Email OTP Verification Page
/// [REQ-AUTH-OTP-001] Email: 30s cooldown, 20 attempts/device
/// [customer_app_whitepaper.md Section 1.1]
class EmailOTPPage extends ConsumerStatefulWidget {
  final String deviceId;
  final Function(String email) onVerified;

  const EmailOTPPage({
    super.key,
    required this.deviceId,
    required this.onVerified,
  });

  @override
  ConsumerState<EmailOTPPage> createState() => _EmailOTPPageState();
}

class _EmailOTPPageState extends ConsumerState<EmailOTPPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  int _cooldownSeconds = 0;
  int _remainingAttempts = 20;
  Timer? _cooldownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRateLimitInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRateLimitInfo() async {
    final otpService = ref.read(otpServiceProvider);
    final info = await otpService.getRateLimitInfo(
      deviceId: widget.deviceId,
      otpType: OTPType.email,
    );

    if (mounted) {
      setState(() {
        _remainingAttempts = info.remainingAttempts;
        if (info.isLocked) {
          _errorMessage = '已達裝置發送上限（20次），請聯絡客服';
        }
      });
    }
  }

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '請輸入有效的 Email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpService = ref.read(otpServiceProvider);
      final result = await otpService.sendOTP(
        identifier: email,
        otpType: OTPType.email,
        deviceId: widget.deviceId,
      );

      if (mounted) {
        if (result.success) {
          setState(() {
            _otpSent = true;
            _cooldownSeconds = 30; // [REQ-AUTH-OTP-001] 30s cooldown
            _remainingAttempts = result.remainingAttempts ?? _remainingAttempts - 1;
          });
          _startCooldown();

          if (context.mounted) {
            CBToast.show(
              context: context,
              message: '驗證碼已發送',
              type: CBToastType.success,
            );
          }
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? '發送失敗，請稍後再試';
          });
        }
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

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOTP() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();

    if (code.isEmpty || code.length != 6) {
      setState(() => _errorMessage = '請輸入6位數驗證碼');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpService = ref.read(otpServiceProvider);
      final result = await otpService.verifyOTP(
        identifier: email,
        otpCode: code,
        otpType: OTPType.email,
        deviceId: widget.deviceId,
      );

      if (mounted) {
        if (result.verified) {
          widget.onVerified(email);
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? '驗證碼錯誤';
          });
        }
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
    final isLocked = _remainingAttempts <= 0;

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('Email 驗證'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              '請輸入您的 Email',
              style: TextStyle(
                fontSize: DesignTokens.fs2xl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),

            const SizedBox(height: DesignTokens.sp2),

            // Policy notice
            // [customer_app_whitepaper.md Section 1.2]
            Container(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              decoration: BoxDecoration(
                color: DesignTokens.bgSubtle,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Text(
                '為了避免帳號的濫用，一個 Email / 一隻手機號碼都只能註冊一隻帳號；一部手機也只能註冊一次帳號。敬請愛惜您的帳號。',
                style: TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Email input
            CBInput(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: '輸入 Email',
              enabled: !_otpSent && !isLocked,
            ),

            const SizedBox(height: DesignTokens.sp4),

            // Send OTP button
            CBButton(
              text: _cooldownSeconds > 0
                  ? '重新發送 ($_cooldownSeconds秒)'
                  : (_otpSent ? '重新送出驗證碼' : '發送驗證碼'),
              onPressed: (_cooldownSeconds > 0 || isLocked || _isLoading)
                  ? null
                  : _sendOTP,
              isLoading: _isLoading && !_otpSent,
              size: CBButtonSize.large,
            ),

            if (_otpSent) ...[
              const SizedBox(height: DesignTokens.sp6),

              // OTP input
              CBInput(
                label: '驗證碼',
                controller: _otpController,
                keyboardType: TextInputType.number,
                hintText: '輸入6位數驗證碼',
                maxLines: 1,
              ),

              const SizedBox(height: DesignTokens.sp4),

              // Verify button
              CBButton(
                text: '驗證',
                onPressed: _isLoading ? null : _verifyOTP,
                isLoading: _isLoading && _otpSent,
                size: CBButtonSize.large,
              ),
            ],

            const SizedBox(height: DesignTokens.sp6),

            // Attempts info
            // [REQ-AUTH-OTP-001] 20 attempts/device
            Text(
              '剩餘嘗試次數：$_remainingAttempts / 20',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
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

