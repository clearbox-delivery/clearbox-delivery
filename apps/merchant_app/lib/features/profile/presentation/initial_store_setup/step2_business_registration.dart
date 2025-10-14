import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

/// Step 2: Business Registration
/// [merchant_app_whitepaper.md Section 2 (二)]
class Step2BusinessRegistration extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;

  const Step2BusinessRegistration({super.key, required this.onNext});

  @override
  State<Step2BusinessRegistration> createState() => _Step2BusinessRegistrationState();
}

class _Step2BusinessRegistrationState extends State<Step2BusinessRegistration> {
  final _taxIdController = TextEditingController();
  final _registeredNameController = TextEditingController();
  final _registeredAddressController = TextEditingController();
  final _ownerNameController = TextEditingController();

  @override
  void dispose() {
    _taxIdController.dispose();
    _registeredNameController.dispose();
    _registeredAddressController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    widget.onNext({
      'taxId': _taxIdController.text,
      'registeredName': _registeredNameController.text,
      'registeredAddress': _registeredAddressController.text,
      'ownerName': _ownerNameController.text,
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
            '營業登記驗證',
            style: TextStyle(fontSize: DesignTokens.fs2xl, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: DesignTokens.sp6),
          CBInput(label: '統一編號', controller: _taxIdController, hintText: '輸入統一編號'),
          const SizedBox(height: DesignTokens.sp4),
          CBInput(label: '登記名稱', controller: _registeredNameController, hintText: '輸入登記名稱'),
          const SizedBox(height: DesignTokens.sp4),
          CBInput(label: '登記地址', controller: _registeredAddressController, hintText: '輸入登記地址', maxLines: 2),
          const SizedBox(height: DesignTokens.sp4),
          CBInput(label: '負責人姓名', controller: _ownerNameController, hintText: '輸入負責人姓名'),
          const SizedBox(height: DesignTokens.sp8),
          CBButton(text: '下一步', onPressed: _handleNext, size: CBButtonSize.large),
        ],
      ),
    );
  }
}

