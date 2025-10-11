import 'package:flutter/material.dart';
import 'dart:async';

/// Button with cooldown timer for OTP resend
/// [REQ-AUTH-OTP-001] Email: 30s cooldown
/// [REQ-AUTH-OTP-002] Phone: 2min cooldown
class CooldownButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Duration cooldownDuration;
  final String text;
  final String cooldownText;

  const CooldownButton({
    super.key,
    required this.onPressed,
    required this.cooldownDuration,
    this.text = 'Send',
    this.cooldownText = 'Resend in',
  });

  @override
  State<CooldownButton> createState() => _CooldownButtonState();
}

class _CooldownButtonState extends State<CooldownButton> {
  bool _isCooldown = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  void _handlePress() {
    widget.onPressed();
    setState(() {
      _isCooldown = true;
      _remainingSeconds = widget.cooldownDuration.inSeconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isCooldown = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isCooldown ? null : _handlePress,
      child: Text(
        _isCooldown
            ? '${widget.cooldownText} ${_remainingSeconds}s'
            : widget.text,
      ),
    );
  }
}


