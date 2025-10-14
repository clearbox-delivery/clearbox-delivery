import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

/// Step 1: Store Basic Info
/// [merchant_app_whitepaper.md Section 2 (一)]
class Step1StoreInfo extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;

  const Step1StoreInfo({super.key, required this.onNext});

  @override
  State<Step1StoreInfo> createState() => _Step1StoreInfoState();
}

class _Step1StoreInfoState extends State<Step1StoreInfo> {
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _businessHoursController = TextEditingController();

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _mapsLinkController.dispose();
    _businessHoursController.dispose();
    super.dispose();
  }

  void _handleNext() {
    widget.onNext({
      'storeName': _storeNameController.text,
      'address': _addressController.text,
      'mapsLink': _mapsLinkController.text,
      'businessHours': _businessHoursController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '店家基本資料',
            style: TextStyle(
              fontSize: DesignTokens.fs2xl,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp6),
          CBInput(label: '店名', controller: _storeNameController, hintText: '輸入店名'),
          const SizedBox(height: DesignTokens.sp4),
          CBInput(label: '地址', controller: _addressController, hintText: '輸入完整地址', maxLines: 2),
          const SizedBox(height: DesignTokens.sp4),
          CBInput(label: 'Google Maps 連結', controller: _mapsLinkController, hintText: 'https://maps.google.com/...'),
          const SizedBox(height: DesignTokens.sp4),
          CBInput(label: '營業時間', controller: _businessHoursController, hintText: '例如：10:00-22:00'),
          const SizedBox(height: DesignTokens.sp8),
          CBButton(text: '下一步', onPressed: _handleNext, size: CBButtonSize.large),
        ],
      ),
    );
  }
}

