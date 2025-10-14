import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

/// Step 3: Food Registration
/// [merchant_app_whitepaper.md Section 2 (三)]
class Step3FoodRegistration extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  
  const Step3FoodRegistration({super.key, required this.onNext});

  @override
  State<Step3FoodRegistration> createState() => _Step3FoodRegistrationState();
}

class _Step3FoodRegistrationState extends State<Step3FoodRegistration> {
  final _foodRegNumberController = TextEditingController();

  @override
  void dispose() {
    _foodRegNumberController.dispose();
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
            '食品業者登錄驗證',
            style: TextStyle(fontSize: DesignTokens.fs2xl, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: DesignTokens.sp6),
          CBInput(label: '食品業者登錄字號', controller: _foodRegNumberController, hintText: '輸入字號'),
          const SizedBox(height: DesignTokens.sp8),
          CBButton(
            text: '下一步',
            onPressed: () => widget.onNext({'foodRegNumber': _foodRegNumberController.text}),
            size: CBButtonSize.large,
          ),
        ],
      ),
    );
  }
}

