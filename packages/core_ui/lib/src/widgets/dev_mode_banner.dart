import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// Dev Mode Warning Banner
/// [docs/DEVICE_SECURITY.md] Shows when ALLOW_DEV_MODE=true
class DevModeBanner extends StatelessWidget {
  const DevModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp4,
        vertical: DesignTokens.sp2,
      ),
      color: DesignTokens.warn,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: DesignTokens.textOnInverse,
          ),
          const SizedBox(width: DesignTokens.sp2),
          const Text(
            '開發模式 - 安全檢查已略過',
            style: TextStyle(
              fontSize: DesignTokens.fsSm,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textOnInverse,
            ),
          ),
        ],
      ),
    );
  }
}

