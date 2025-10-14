import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:courier_app/features/orders/flow/stage3_wait_merchant_page.dart';

/// Stage 2: Go to Merchant (前往店家)
/// [courier_app_whitepaper.md Section 4.2 進度2]
/// [REQ-COU-FLOW-002] Navigate to merchant with photo verification
/// [REQ-COU-VERIF-001] Arrival photo and pickup code
class Stage2GoMerchantPage extends ConsumerStatefulWidget {
  final Order order;

  const Stage2GoMerchantPage({super.key, required this.order});

  @override
  ConsumerState<Stage2GoMerchantPage> createState() => _Stage2GoMerchantPageState();
}

class _Stage2GoMerchantPageState extends ConsumerState<Stage2GoMerchantPage> {
  String? _pickupPhotoUrl;
  final _pickupCodeController = TextEditingController();
  bool _codeVerified = false;

  @override
  void dispose() {
    _pickupCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('前往店家'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Delivery icon
            const Icon(
              Icons.store_outlined,
              size: 80,
              color: DesignTokens.brand,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Merchant info placeholder
            Text(
              '請前往店家取餐',
              style: const TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp4),

            const Text(
              '店家地址（待整合 merchant_profiles）',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Distance and ETA placeholder
            Container(
              padding: const EdgeInsets.all(DesignTokens.sp4),
              decoration: BoxDecoration(
                color: DesignTokens.bgSubtle,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: DesignTokens.brand),
                      SizedBox(width: DesignTokens.sp2),
                      Text(
                        '距離 1.5km',
                        style: TextStyle(
                          fontSize: DesignTokens.fsMd,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.sp2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: DesignTokens.brand),
                      SizedBox(width: DesignTokens.sp2),
                      Text(
                        'ETA 5 分鐘',
                        style: TextStyle(
                          fontSize: DesignTokens.fsMd,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.sp8),

            // Google Maps link placeholder
            CBButton(
              text: '開啟 Google Maps 導航',
              onPressed: () {
                CBToast.show(
                  context: context,
                  message: 'Google Maps 導航開發中',
                  type: CBToastType.info,
                );
              },
              variant: CBButtonVariant.secondary,
              size: CBButtonSize.large,
              icon: Icons.map_outlined,
            ),

            const SizedBox(height: DesignTokens.sp4),

            // Pickup photo upload
            if (_pickupPhotoUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: DesignTokens.sp4),
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: DesignTokens.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Image.network(
                    _pickupPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              ),

            CBButton(
              text: _pickupPhotoUrl == null ? '到店拍照' : '重新拍照',
              onPressed: _handleTakePickupPhoto,
              variant: CBButtonVariant.secondary,
              size: CBButtonSize.large,
              icon: Icons.camera_alt,
            ),

            const SizedBox(height: DesignTokens.sp4),

            // Pickup code input
            CBInput(
              label: '取餐碼（6位數）',
              controller: _pickupCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !_codeVerified,
              suffixIcon: _codeVerified
                  ? const Icon(Icons.check_circle, color: DesignTokens.success)
                  : null,
            ),

            const SizedBox(height: DesignTokens.sp4),

            if (!_codeVerified)
              CBButton(
                text: '驗證取餐碼',
                onPressed: _handleVerifyCode,
                variant: CBButtonVariant.secondary,
                size: CBButtonSize.large,
                icon: Icons.pin_outlined,
              ),

            const SizedBox(height: DesignTokens.sp6),

            // Proceed to Stage3
            CBButton(
              text: '已取餐，前往送達',
              onPressed: (_pickupPhotoUrl != null && _codeVerified)
                  ? () => _proceedToStage3(context)
                  : null,
              size: CBButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTakePickupPhoto() async {
    try {
      List<int>? fileBytes;

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          fileBytes = result.files.first.bytes;
        }
      } else {
        final picker = ImagePicker();
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('選擇來源'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('拍照'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('從相簿選擇'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        if (source != null) {
          final XFile? image = await picker.pickImage(source: source);
          if (image != null) {
            fileBytes = await image.readAsBytes();
          }
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) return;

      if (mounted) {
        CBToast.show(
          context: context,
          message: '上傳中...',
          type: CBToastType.info,
        );
      }

      final storageService = ref.read(storageServiceProvider);
      final url = await storageService.uploadOrderPhoto(
        orderId: widget.order.id,
        photoType: 'pickup',
        fileBytes: fileBytes,
      );

      if (url != null && mounted) {
        setState(() => _pickupPhotoUrl = url);
        CBToast.show(
          context: context,
          message: '到店照片上傳成功',
          type: CBToastType.success,
        );
      } else if (mounted) {
        CBToast.show(
          context: context,
          message: '上傳失敗，請重試',
          type: CBToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        CBToast.show(
          context: context,
          message: '拍照失敗: $e',
          type: CBToastType.error,
        );
      }
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _pickupCodeController.text.trim();
    if (code.length != 6) {
      CBToast.show(
        context: context,
        message: '請輸入 6 位取餐碼',
        type: CBToastType.error,
      );
      return;
    }

    final orderService = ref.read(orderServiceProvider);
    final verified = await orderService.verifyPickupCode(
      orderId: widget.order.id,
      code: code,
    );

    if (verified && mounted) {
      setState(() => _codeVerified = true);
      CBToast.show(
        context: context,
        message: '取餐碼驗證成功',
        type: CBToastType.success,
      );
    } else if (mounted) {
      CBToast.show(
        context: context,
        message: '取餐碼錯誤，請重新輸入',
        type: CBToastType.error,
      );
    }
  }

  void _proceedToStage3(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Stage3WaitMerchantPage(order: widget.order),
      ),
    );
  }
}

