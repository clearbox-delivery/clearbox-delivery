import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// ClearBox Input Component
/// Follows UI_GUIDELINES.md input specifications
class CBInput extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;

  const CBInput({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.maxLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp2),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: enabled ? DesignTokens.bg : DesignTokens.bgSubtle,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.sp4,
              vertical: DesignTokens.sp3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(color: DesignTokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(color: DesignTokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(color: DesignTokens.brand, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(color: DesignTokens.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              borderSide: const BorderSide(color: DesignTokens.danger, width: 1),
            ),
            hintStyle: const TextStyle(color: DesignTokens.textMuted),
          ),
        ),
      ],
    );
  }
}

