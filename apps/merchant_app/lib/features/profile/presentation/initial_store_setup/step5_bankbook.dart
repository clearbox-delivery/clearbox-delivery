import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

/// Step 5: Bankbook Photo
/// [merchant_app_whitepaper.md Section 2 (五)]
class Step5Bankbook extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  
  const Step5Bankbook({super.key, required this.onNext});

  @override
  State<Step5Bankbook> createState() => _Step5BankbookState();
}

class _Step5BankbookState extends State<Step5Bankbook> {
  final _accountNumberController = TextEditingController();

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '銀行帳簿正面',
            style: TextStyle(fontSize: DesignTokens.fs2xl, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: DesignTokens.sp4),
          const Text(
            'Dev 模式：可手動上傳照片',
            style: TextStyle(fontSize: DesignTokens.fsSm, color: DesignTokens.textSecondary),
          ),
          const SizedBox(height: DesignTokens.sp6),
          CBButton(
            text: '拍攝帳簿（Dev: 跳過）',
            onPressed: () {},
            icon: Icons.camera_alt,
            variant: CBButtonVariant.secondary,
          ),
          const SizedBox(height: DesignTokens.sp6),
          CBInput(label: '銀行帳號', controller: _accountNumberController, hintText: '手動輸入帳號'),
          const SizedBox(height: DesignTokens.sp8),
          CBButton(
            text: '完成設定',
            onPressed: () => widget.onNext({'bankAccount': _accountNumberController.text}),
            size: CBButtonSize.large,
          ),
        ],
      ),
    );
  }
}

