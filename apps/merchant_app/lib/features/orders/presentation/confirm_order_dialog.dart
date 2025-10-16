import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Confirm Order Dialog (4-step flow)
/// [merchant_app_whitepaper.md Section 4.1]
class ConfirmOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const ConfirmOrderDialog({super.key, required this.order});

  @override
  ConsumerState<ConfirmOrderDialog> createState() => _ConfirmOrderDialogState();
}

class _ConfirmOrderDialogState extends ConsumerState<ConfirmOrderDialog> {
  int _step = 0;
  bool _stockOk = true;
  bool _volumeOk = true;
  int _prepMinutes = 15;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    try {
      final orderService = ref.read(orderServiceProvider);

      // Call merchant_confirm RPC
      await orderService.merchantConfirm(
        orderId: widget.order.id,
        stockOk: _stockOk,
        volumeOk: _volumeOk,
        prepMinutes: _prepMinutes,
        note: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        CBToast.show(
          context: context,
          message: '已確認訂單',
          type: CBToastType.success,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '確認失敗: $e',
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
            Text(
              '確認訂單 (${_step + 1}/4)',
              style: const TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.sp6),

            _buildStepContent(),

            const SizedBox(height: DesignTokens.sp6),

            if (_step < 3) ...[
              CBButton(
                text: '下一步',
                onPressed: () => setState(() => _step++),
                size: CBButtonSize.large,
              ),
            ] else ...[
              CBButton(
                text: '確認可接',
                onPressed: _isLoading ? null : _handleConfirm,
                isLoading: _isLoading,
                size: CBButtonSize.large,
              ),
            ],

            const SizedBox(height: DesignTokens.sp3),

            if (_step > 0)
              CBButton(
                text: '上一步',
                onPressed: () => setState(() => _step--),
                type: CBButtonType.secondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStockCheck();
      case 1:
        return _buildVolumeCheck();
      case 2:
        return _buildPrepTime();
      case 3:
        return _buildNotes();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStockCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A. 存貨核對',
          style: TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp4),
        ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.sp2),
              child: Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (v) {},
                    activeColor: DesignTokens.accent,
                  ),
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      style: const TextStyle(
                        fontSize: DesignTokens.fsMd,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: DesignTokens.sp4),
        Row(
          children: [
            Checkbox(
              value: _stockOk,
              onChanged: (v) => setState(() => _stockOk = v ?? true),
              activeColor: DesignTokens.accent,
            ),
            const Text(
              '所有品項可出貨',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeCheck() {
    final totalItems = widget.order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'B. 載運量檢查',
          style: TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp4),
        Text(
          '總品項數: $totalItems',
          style: const TextStyle(
            fontSize: DesignTokens.fsMd,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp2),
        Text(
          totalItems > 5 ? '建議拆單（系統可自動複製為兩張訂單）' : '載運量在正常範圍',
          style: TextStyle(
            fontSize: DesignTokens.fsSm,
            color: totalItems > 5 ? DesignTokens.warn : DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp4),
        Row(
          children: [
            Checkbox(
              value: _volumeOk,
              onChanged: (v) => setState(() => _volumeOk = v ?? true),
              activeColor: DesignTokens.accent,
            ),
            const Text(
              '載運量 OK，可單趟配送',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrepTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'C. 預期備餐時間',
          style: TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp4),
        Wrap(
          spacing: DesignTokens.sp3,
          children: [10, 15, 20, 25, 30].map((minutes) {
            final isSelected = _prepMinutes == minutes;
            return ChoiceChip(
              label: Text('$minutes 分鐘'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _prepMinutes = minutes);
              },
              selectedColor: DesignTokens.brand.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? DesignTokens.brand : DesignTokens.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'D. 備註',
          style: TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp4),
        CBInput(
          controller: _notesController,
          hintText: '例如：現煎需久、需保溫袋等',
          maxLines: 3,
        ),
      ],
    );
  }
}

