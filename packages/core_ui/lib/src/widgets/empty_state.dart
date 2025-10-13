import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';
import 'package:core_ui/src/widgets/cb_button.dart';

/// ClearBox Empty State Component
/// Shows when list/content is empty with optional action
class CBEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CBEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: DesignTokens.sp4),
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignTokens.fsLg,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: DesignTokens.sp2),
              Text(
                description!,
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.sp6),
              CBButton(
                text: actionLabel!,
                onPressed: onAction,
                type: CBButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Component
class CBErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CBErrorState({
    super.key,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.danger,
            ),
            const SizedBox(height: DesignTokens.sp4),
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignTokens.fsLg,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: DesignTokens.sp2),
              Text(
                description!,
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.sp6),
              CBButton(
                text: actionLabel!,
                onPressed: onAction,
                type: CBButtonType.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

