import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Cancel Order Dialog
/// [merchant_app_whitepaper.md Section 4.1]
class CancelOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const CancelOrderDialog({super.key, required this.order});

  @override
  ConsumerState<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends ConsumerState<CancelOrderDialog> {
  CancelReason _selectedReason = CancelReason.outOfStock;
  bool _isLoading = false;

  Future<void> _handleCancel() async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);

      await orderService.merchantCancel(
        orderId: widget.order.id,
        reason: _selectedReason.name,
      );

      if (mounted) {
        Navigator.pop(context, true);
        CBToast.show(
          context: context,
          message: '已取消訂單',
          type: CBToastType.success,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '取消失敗: $e',
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
              '無法接單',
              style: TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.sp2),
            const Text(
              '請選擇原因',
              style: TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.sp6),

            ...CancelReason.values.map((reason) => RadioListTile<CancelReason>(
                  title: Text(
                    reason.label,
                    style: const TextStyle(
                      fontSize: DesignTokens.fsMd,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedReason = value);
                    }
                  },
                  activeColor: DesignTokens.brand,
                  contentPadding: EdgeInsets.zero,
                )),

            const SizedBox(height: DesignTokens.sp6),

            Row(
              children: [
                Expanded(
                  child: CBButton(
                    text: '返回',
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    variant: CBButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: DesignTokens.sp4),
                Expanded(
                  child: CBButton(
                    text: '確認取消',
                    onPressed: _isLoading ? null : _handleCancel,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

