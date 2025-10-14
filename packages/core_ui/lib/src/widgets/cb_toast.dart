import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// ClearBox Toast Component
/// [UI_GUIDELINES.md] Toast notifications with auto-dismiss
enum CBToastType { info, success, warning, error }

class CBToast {
  /// Show toast notification
  /// Auto-dismisses after 3 seconds
  static void show({
    required BuildContext context,
    required String message,
    CBToastType type = CBToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CBToastWidget(
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _CBToastWidget extends StatefulWidget {
  final String message;
  final CBToastType type;
  final VoidCallback onDismiss;

  const _CBToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_CBToastWidget> createState() => _CBToastWidgetState();
}

class _CBToastWidgetState extends State<_CBToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durBase,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DesignTokens.easeStandard,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DesignTokens.easeStandard,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case CBToastType.success:
        return DesignTokens.accent;
      case CBToastType.warning:
        return DesignTokens.warn;
      case CBToastType.error:
        return DesignTokens.danger;
      case CBToastType.info:
      default:
        return DesignTokens.brand;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case CBToastType.success:
        return Icons.check_circle_outline;
      case CBToastType.warning:
        return Icons.warning_amber_outlined;
      case CBToastType.error:
        return Icons.error_outline;
      case CBToastType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: DesignTokens.sp6,
      right: DesignTokens.sp6,
      left: DesignTokens.sp6,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                boxShadow: [DesignTokens.shadowMd],
              ),
              child: Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.sp3),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onDismiss,
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

