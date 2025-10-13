import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:uuid/uuid.dart';

/// OTP 验证页面
/// [REQ-AUTH-OTP-001] Email OTP: 20次/设备, 30秒冷却
/// [REQ-AUTH-OTP-002] Phone OTP: 5次/设备, 2分钟冷却
class OTPVerificationPage extends ConsumerStatefulWidget {
  final String identifier;
  final String otpType; // 'EMAIL' or 'PHONE'

  const OTPVerificationPage({
    super.key,
    required this.identifier,
    required this.otpType,
  });

  @override
  ConsumerState<OTPVerificationPage> createState() =>
      _OTPVerificationPageState();
}

class _OTPVerificationPageState extends ConsumerState<OTPVerificationPage> {
  String _otpCode = '';
  bool _isLoading = false;
  bool _canResend = false;
  String? _devOtpCode; // 开发环境显示
  late String _deviceId;

  @override
  void initState() {
    super.initState();
    _deviceId = const Uuid().v4(); // 实际应使用设备唯一标识
    _sendOTP();
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);

    try {
      final otpService = ref.read(otpServiceProvider);
      final result = await otpService.sendOTP(
        identifier: widget.identifier,
        otpType: widget.otpType,
        deviceId: _deviceId,
      );

      if (mounted) {
        setState(() {
          _devOtpCode = result['otp_code']; // 开发环境
          _canResend = false;
        });

        // 设置冷却时间
        final cooldown = widget.otpType == 'EMAIL' ? 30 : 120;
        Future.delayed(Duration(seconds: cooldown), () {
          if (mounted) {
            setState(() => _canResend = true);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('驗證碼已發送${_devOtpCode != null ? " (開發: $_devOtpCode)" : ""}'),
            backgroundColor: DesignTokens.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('發送失敗: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      _showError('請輸入完整驗證碼');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpService = ref.read(otpServiceProvider);
      final verified = await otpService.verifyOTP(
        identifier: widget.identifier,
        otpCode: _otpCode,
        otpType: widget.otpType,
        deviceId: _deviceId,
      );

      if (verified && mounted) {
        Navigator.pop(context, true);
      } else {
        _showError('驗證碼錯誤');
      }
    } catch (e) {
      if (mounted) {
        _showError('驗證失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(
          widget.otpType == 'EMAIL' ? 'Email 驗證' : '手機驗證',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DesignTokens.sp8),
            
            const Icon(
              Icons.security,
              size: 64,
              color: DesignTokens.brand,
            ),
            
            const SizedBox(height: DesignTokens.sp6),
            
            Text(
              '驗證碼已發送至',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sp2),
            
            Text(
              widget.identifier,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DesignTokens.fsMd,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sp8),
            
            OtpInputField(
              length: 6,
              onChanged: (value) {
                setState(() => _otpCode = value);
              },
              onCompleted: (value) {
                _otpCode = value;
                _verifyOTP();
              },
            ),
            
            const SizedBox(height: DesignTokens.sp6),
            
            CBButton(
              text: '驗證',
              onPressed: _isLoading ? null : _verifyOTP,
              isLoading: _isLoading,
              size: CBButtonSize.large,
            ),
            
            const SizedBox(height: DesignTokens.sp4),
            
            Center(
              child: CooldownButton(
                onPressed: _sendOTP,
                cooldownDuration: Duration(
                  seconds: widget.otpType == 'EMAIL' ? 30 : 120,
                ),
                text: '重新發送',
                cooldownText: '重新發送',
              ),
            ),
            
            const SizedBox(height: DesignTokens.sp6),
            
            Text(
              widget.otpType == 'EMAIL'
                  ? '每個裝置最多 20 次嘗試，30秒冷卻'
                  : '每個裝置最多 5 次嘗試，2分鐘冷卻',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

