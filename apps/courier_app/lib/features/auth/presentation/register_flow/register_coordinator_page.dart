import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier_app/features/auth/presentation/register_flow/email_otp_page.dart';
import 'package:courier_app/features/auth/presentation/register_flow/phone_otp_page.dart';
import 'package:courier_app/features/auth/presentation/register_flow/set_password_page.dart';
import 'package:uuid/uuid.dart';

/// Registration Flow Coordinator
/// [customer_app_whitepaper.md Section 1.1] Three-step registration
/// Step 1: Email OTP -> Step 2: Phone OTP -> Step 3: Set Password
class RegisterCoordinatorPage extends ConsumerStatefulWidget {
  const RegisterCoordinatorPage({super.key});

  @override
  ConsumerState<RegisterCoordinatorPage> createState() =>
      _RegisterCoordinatorPageState();
}

class _RegisterCoordinatorPageState
    extends ConsumerState<RegisterCoordinatorPage> {
  final String _deviceId = const Uuid().v4();
  
  int _currentStep = 0;
  String? _verifiedEmail;
  String? _verifiedPhone;

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return EmailOTPPage(
          deviceId: _deviceId,
          onVerified: (email) {
            setState(() {
              _verifiedEmail = email;
              _currentStep = 1;
            });
          },
        );
      case 1:
        return PhoneOTPPage(
          deviceId: _deviceId,
          onVerified: (phone) {
            setState(() {
              _verifiedPhone = phone;
              _currentStep = 2;
            });
          },
        );
      case 2:
        return SetPasswordPage(
          email: _verifiedEmail!,
          phone: _verifiedPhone!,
          deviceId: _deviceId,
        );
      default:
        return const Scaffold(
          body: Center(child: Text('Unknown step')),
        );
    }
  }
}

