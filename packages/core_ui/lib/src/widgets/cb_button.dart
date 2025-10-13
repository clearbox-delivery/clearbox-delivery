import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// ClearBox Button Component
/// Follows UI_GUIDELINES.md button specifications
enum CBButtonType { primary, secondary, tertiary }
enum CBButtonSize { medium, large }

class CBButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CBButtonType type;
  final CBButtonSize size;
  final bool isLoading;
  final IconData? icon;

  const CBButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CBButtonType.primary,
    this.size = CBButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final height = size == CBButtonSize.large ? 48.0 : 44.0;

    if (type == CBButtonType.primary) {
      return SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.brand,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.sp6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: DesignTokens.sp2),
                    ],
                    Text(text),
                  ],
                ),
        ),
      );
    } else if (type == CBButtonType.secondary) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.textPrimary,
            side: const BorderSide(color: DesignTokens.border),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.sp6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: DesignTokens.sp2),
                    ],
                    Text(text),
                  ],
                ),
        ),
      );
    } else {
      // Tertiary
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.brand,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.sp4,
            vertical: DesignTokens.sp2,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: DesignTokens.sp1),
                  ],
                  Text(text),
                ],
              ),
      );
    }
  }
}

