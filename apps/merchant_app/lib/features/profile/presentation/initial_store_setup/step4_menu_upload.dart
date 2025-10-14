import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

/// Step 4: Menu Upload
/// [merchant_app_whitepaper.md Section 2 (四)]
class Step4MenuUpload extends StatelessWidget {
  final Function(Map<String, dynamic>) onNext;
  
  const Step4MenuUpload({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '建立菜單',
            style: TextStyle(fontSize: DesignTokens.fs2xl, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: DesignTokens.sp4),
          const Text(
            '上傳菜單照片，系統會自動轉換成可編輯的菜單',
            style: TextStyle(fontSize: DesignTokens.fsSm, color: DesignTokens.textSecondary),
          ),
          const SizedBox(height: DesignTokens.sp6),
          CBButton(
            text: '上傳菜單照片（Dev: 跳過）',
            onPressed: () => onNext({'menuUploaded': true}),
            icon: Icons.upload_file,
            variant: CBButtonVariant.secondary,
          ),
          const SizedBox(height: DesignTokens.sp8),
          CBButton(text: '下一步', onPressed: () => onNext({}), size: CBButtonSize.large),
        ],
      ),
    );
  }
}

