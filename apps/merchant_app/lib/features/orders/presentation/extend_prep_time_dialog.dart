import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Extend Prep Time Dialog (+5/+10 minutes)
/// [merchant_app_whitepaper.md Section 4.3]
class ExtendPrepTimeDialog extends ConsumerStatefulWidget {
  final Order order;

  const ExtendPrepTimeDialog({super.key, required this.order});

  @override
  ConsumerState<ExtendPrepTimeDialog> createState() => _ExtendPrepTimeDialogState();
}

class _ExtendPrepTimeDialogState extends ConsumerState<ExtendPrepTimeDialog> {
  bool _isLoading = false;

  Future<void> _handleExtend(int plusMinutes) async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);

      await orderService.merchantExtendPrepTime(
        orderId: widget.order.id,
        plusMinutes: plusMinutes,
      );

      if (mounted) {
        Navigator.pop(context, true);
        CBToast.show(
          context: context,
          message: '已延長 $plusMinutes 分鐘',
          type: CBToastType.success,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '操作失敗: $e',
          type: CBToastType.error,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DesignTokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '需要更多時間',
              style: TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),

            const SizedBox(height: DesignTokens.sp2),

            const Text(
              '選擇要延長的時間',
              style: TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Current prep time
            if (widget.order.prepTimeMinutes != null) ...[
              Container(
                padding: const EdgeInsets.all(DesignTokens.sp3),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSubtle,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Text(
                  '目前備餐時間: ${widget.order.prepTimeMinutes} 分鐘',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: DesignTokens.sp6),
            ],

            // Extend buttons
            Row(
              children: [
                Expanded(
                  child: CBButton(
                    text: '+5 分鐘',
                    onPressed: _isLoading ? null : () => _handleExtend(5),
                    type: CBButtonType.secondary,
                    size: CBButtonSize.large,
                  ),
                ),
                const SizedBox(width: DesignTokens.sp4),
                Expanded(
                  child: CBButton(
                    text: '+10 分鐘',
                    onPressed: _isLoading ? null : () => _handleExtend(10),
                    type: CBButtonType.secondary,
                    size: CBButtonSize.large,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignTokens.sp4),

            CBButton(
              text: '關閉',
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              type: CBButtonType.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

