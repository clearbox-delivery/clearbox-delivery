import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

/// Stage 4: Go to Customer (前往顧客)
/// [courier_app_whitepaper.md Section 4.2 進度4]
/// [REQ-COU-FLOW-004] Navigate to customer, delivery completion placeholder
class Stage4GoCustomerPage extends ConsumerStatefulWidget {
  final Order order;

  const Stage4GoCustomerPage({super.key, required this.order});

  @override
  ConsumerState<Stage4GoCustomerPage> createState() => _Stage4GoCustomerPageState();
}

class _Stage4GoCustomerPageState extends ConsumerState<Stage4GoCustomerPage> {
  bool _isCompleting = false;
  String? _deliveryPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('前往顧客'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Delivery icon
            const Icon(
              Icons.person_pin_circle_outlined,
              size: 80,
              color: DesignTokens.brand,
            ),

            const SizedBox(height: DesignTokens.sp6),

            const Text(
              '前往顧客收件地址',
              style: TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignTokens.sp4),

            const Text(
              '收件地址（待整合 customer_addresses）',
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
                        '距離 2.3km',
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
                        'ETA 8 分鐘',
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

            // Contact customer
            CBButton(
              text: '聯絡顧客',
              onPressed: () {
                CBToast.show(
                  context: context,
                  message: '聯絡顧客功能開發中（雙向遮罩保護）',
                  type: CBToastType.info,
                );
              },
              variant: CBButtonVariant.secondary,
              size: CBButtonSize.large,
              icon: Icons.phone_outlined,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Delivery photo upload
            if (_deliveryPhotoUrl != null)
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
                    _deliveryPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              ),

            CBButton(
              text: _deliveryPhotoUrl == null ? '送達拍照' : '重新拍照',
              onPressed: _handleTakeDeliveryPhoto,
              variant: CBButtonVariant.secondary,
              size: CBButtonSize.large,
              icon: Icons.camera_alt,
            ),

            const SizedBox(height: DesignTokens.sp6),

            // Complete delivery button
            CBButton(
              text: '完成送達',
              onPressed: (_deliveryPhotoUrl != null && !_isCompleting)
                  ? () => _handleComplete(context)
                  : null,
              isLoading: _isCompleting,
              size: CBButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTakeDeliveryPhoto() async {
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
        photoType: 'delivered',
        fileBytes: fileBytes,
      );

      if (url != null && mounted) {
        setState(() => _deliveryPhotoUrl = url);
        CBToast.show(
          context: context,
          message: '送達照片上傳成功',
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

  Future<void> _handleComplete(BuildContext context) async {
    if (_deliveryPhotoUrl == null) {
      CBToast.show(
        context: context,
        message: '請先拍攝送達照片',
        type: CBToastType.error,
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      await ref.read(orderServiceProvider).markDelivered(
        orderId: widget.order.id,
        deliveryPhotoUrl: _deliveryPhotoUrl,
      );

      if (context.mounted) {
        CBToast.show(
          context: context,
          message: '訂單已完成！',
          type: CBToastType.success,
        );

        // Return to current orders (home)
        context.go('/current-orders');
      }
    } catch (e) {
      if (context.mounted) {
        CBToast.show(
          context: context,
          message: '完成失敗: $e',
          type: CBToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}

