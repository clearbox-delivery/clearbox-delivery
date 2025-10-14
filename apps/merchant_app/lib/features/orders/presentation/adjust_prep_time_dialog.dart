import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Adjust Prep Time Dialog
/// [merchant_app_whitepaper.md Section 4.2] ±5 分鐘調整
class AdjustPrepTimeDialog extends ConsumerStatefulWidget {
  final Order order;

  const AdjustPrepTimeDialog({super.key, required this.order});

  @override
  ConsumerState<AdjustPrepTimeDialog> createState() => _AdjustPrepTimeDialogState();
}

class _AdjustPrepTimeDialogState extends ConsumerState<AdjustPrepTimeDialog> {
  late int _currentPrepTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPrepTime = widget.order.prepTimeMinutes ?? 15;
  }

  Future<void> _handleAdjust(int delta) async {
    final newTime = _currentPrepTime + delta;

    // Validate range (5-60 minutes)
    if (newTime < 5 || newTime > 60) {
      CBToast.show(
        context: context,
        message: '備餐時間需在 5-60 分鐘之間',
        type: CBToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);

      await orderService.merchantAdjustPrepTime(
        orderId: widget.order.id,
        deltaMinutes: delta,
      );

      if (mounted) {
        setState(() => _currentPrepTime = newTime);
        CBToast.show(
          context: context,
          message: '已更新備餐時間',
          type: CBToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '更新失敗: $e',
          type: CBToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              '調整備餐時間',
              style: TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Current prep time display
            Center(
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.sp4),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSubtle,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Text(
                  '$_currentPrepTime 分鐘',
                  style: const TextStyle(
                    fontSize: DesignTokens.fs2xl,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.brand,
                  ),
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Adjustment buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAdjustButton('-5 分', -5),
                _buildAdjustButton('+5 分', 5),
              ],
            ),

            const SizedBox(height: DesignTokens.sp6),

            CBButton(
              text: '關閉',
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              variant: CBButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton(String label, int delta) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _handleAdjust(delta),
      style: ElevatedButton.styleFrom(
        backgroundColor: delta > 0 ? DesignTokens.accent : DesignTokens.warn,
        foregroundColor: DesignTokens.textOnInverse,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.sp6,
          vertical: DesignTokens.sp3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: DesignTokens.fsMd,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

