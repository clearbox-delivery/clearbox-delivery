import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// ClearBox Modal Component
/// [UI_GUIDELINES.md] Modal overlay with backdrop and animation
class CBModal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final VoidCallback? onClose;

  const CBModal({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(DesignTokens.sp6),
      child: AnimatedContainer(
        duration: DesignTokens.durBase,
        curve: DesignTokens.easeStandard,
        decoration: BoxDecoration(
          color: DesignTokens.bg,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          boxShadow: [DesignTokens.shadowLg],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.sp6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: DesignTokens.fsXl,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: DesignTokens.textSecondary,
                      ),
                  ],
                ),

                const SizedBox(height: DesignTokens.sp4),

                // Content
                content,

                // Actions
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.sp6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show modal helper
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color.fromRGBO(15, 23, 42, 0.4),
      builder: (context) => CBModal(
        title: title,
        content: content,
        actions: actions,
        onClose: barrierDismissible ? () => Navigator.of(context).pop() : null,
      ),
    );
  }
}

