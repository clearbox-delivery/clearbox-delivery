import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// ClearBox Card Component
/// Follows UI_GUIDELINES.md card specifications
class CBCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool withShadow;

  const CBCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.all(DesignTokens.sp2),
      padding: padding ?? const EdgeInsets.all(DesignTokens.sp6),
      decoration: BoxDecoration(
        color: DesignTokens.bg,
        border: Border.all(color: DesignTokens.border),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: withShadow ? [DesignTokens.shadowSm] : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: card,
      );
    }

    return card;
  }
}

