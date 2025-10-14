import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Address Edit Dialog
/// [customer_app_whitepaper.md Section 2]
class AddressEditDialog extends ConsumerStatefulWidget {
  final UserAddress? address;

  const AddressEditDialog({super.key, this.address});

  @override
  ConsumerState<AddressEditDialog> createState() => _AddressEditDialogState();
}

class _AddressEditDialogState extends ConsumerState<AddressEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _mapsLinkController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _addressController =
        TextEditingController(text: widget.address?.address ?? '');
    _mapsLinkController =
        TextEditingController(text: widget.address?.googleMapsLink ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapsLinkController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final mapsLink = _mapsLinkController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      CBToast.show(
        context: context,
        message: '請填寫地址名稱與地址',
        type: CBToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final addressService = ref.read(addressServiceProvider);

      if (widget.address == null) {
        // Create
        await addressService.createAddress(
          name: name,
          address: address,
          googleMapsLink: mapsLink,
        );
      } else {
        // Update
        await addressService.updateAddress(
          id: widget.address!.id,
          name: name,
          address: address,
          googleMapsLink: mapsLink,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CBToast.show(
          context: context,
          message: '儲存失敗: $e',
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
              widget.address == null ? '新增地址' : '編輯地址',
              style: const TextStyle(
                fontSize: DesignTokens.fsXl,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.sp6),
            CBInput(
              label: '地址名稱',
              controller: _nameController,
              hintText: '例如：家、公司',
            ),
            const SizedBox(height: DesignTokens.sp4),
            CBInput(
              label: '地址',
              controller: _addressController,
              hintText: '輸入完整地址',
              maxLines: 2,
            ),
            const SizedBox(height: DesignTokens.sp4),
            CBInput(
              label: 'Google Maps 連結（選填）',
              controller: _mapsLinkController,
              hintText: 'https://maps.google.com/...',
            ),
            const SizedBox(height: DesignTokens.sp6),
            Row(
              children: [
                Expanded(
                  child: CBButton(
                    text: '取消',
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    variant: CBButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: DesignTokens.sp4),
                Expanded(
                  child: CBButton(
                    text: '儲存',
                    onPressed: _isLoading ? null : _handleSave,
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

