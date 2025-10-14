import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';

/// KYC Flow Page - First-time login document collection
/// [courier_app_whitepaper.md Section 2]
/// [REQ-COU-KYC-001] 7 documents required for courier verification
class KYCFlowPage extends ConsumerStatefulWidget {
  const KYCFlowPage({super.key});

  @override
  ConsumerState<KYCFlowPage> createState() => _KYCFlowPageState();
}

class _KYCFlowPageState extends ConsumerState<KYCFlowPage> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _bankAccountController = TextEditingController();

  // Document upload states
  final Map<String, String?> _documents = {
    'id_front': null,
    'id_back': null,
    'selfie': null,
    'driver_license': null,
    'vehicle_registration': null,
    'police_record': null,
    'bank_book': null,
    'logo_bag': null,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('證件驗證'),
        automaticallyImplyLeading: false, // Cannot skip
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: DesignTokens.sp4),
            child: Row(
              children: [
                CBButton(
                  text: _currentStep == 8 ? '完成' : '下一步',
                  onPressed: details.onStepContinue,
                  size: CBButtonSize.large,
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: DesignTokens.sp3),
                  CBButton(
                    text: '上一步',
                    onPressed: details.onStepCancel,
                    variant: CBButtonVariant.secondary,
                    size: CBButtonSize.large,
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 0: Name
          Step(
            title: const Text('真實姓名'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '請輸入您的真實姓名（需與證件相符）',
                  style: TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp3),
                CBInput(
                  controller: _nameController,
                  labelText: '真實姓名',
                  hintText: '請輸入姓名',
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          // Step 1: ID Front
          _buildDocumentStep(
            title: '身分證正面',
            description: '請清楚拍攝身分證正面',
            docKey: 'id_front',
            stepIndex: 1,
          ),
          // Step 2: ID Back
          _buildDocumentStep(
            title: '身分證反面',
            description: '請清楚拍攝身分證反面',
            docKey: 'id_back',
            stepIndex: 2,
          ),
          // Step 3: Selfie
          _buildDocumentStep(
            title: '正面自拍',
            description: '請拍攝清楚的正面自拍照',
            docKey: 'selfie',
            stepIndex: 3,
          ),
          // Step 4: Driver License
          _buildDocumentStep(
            title: '機車駕照',
            description: '請清楚拍攝機車駕照正面',
            docKey: 'driver_license',
            stepIndex: 4,
          ),
          // Step 5: Vehicle Registration
          _buildDocumentStep(
            title: '機車行照',
            description: '請清楚拍攝機車行照正面',
            docKey: 'vehicle_registration',
            stepIndex: 5,
          ),
          // Step 6: Police Record
          _buildDocumentStep(
            title: '良民證',
            description: '請清楚拍攝良民證',
            docKey: 'police_record',
            stepIndex: 6,
          ),
          // Step 7: Bank Book + Account
          Step(
            title: const Text('銀行帳簿'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '請拍攝銀行帳簿正面並輸入帳號',
                  style: TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp3),
                _buildUploadButton('bank_book'),
                const SizedBox(height: DesignTokens.sp3),
                CBInput(
                  controller: _bankAccountController,
                  labelText: '銀行帳號',
                  hintText: '請輸入完整銀行帳號',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            isActive: _currentStep >= 7,
            state: _currentStep > 7 ? StepState.complete : StepState.indexed,
          ),
          // Step 8: Logo Bag
          _buildDocumentStep(
            title: '保溫袋 Logo',
            description: '請拍攝貼有品牌 Logo 的保溫袋',
            docKey: 'logo_bag',
            stepIndex: 8,
          ),
        ],
      ),
    );
  }

  Step _buildDocumentStep({
    required String title,
    required String description,
    required String docKey,
    required int stepIndex,
  }) {
    return Step(
      title: Text(title),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp3),
          _buildUploadButton(docKey),
          if (_documents[docKey] != null) ...[
            const SizedBox(height: DesignTokens.sp2),
            Row(
              children: [
                const Icon(Icons.check_circle, color: DesignTokens.success, size: 16),
                const SizedBox(width: DesignTokens.sp2),
                const Text(
                  '已上傳',
                  style: TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      isActive: _currentStep >= stepIndex,
      state: _currentStep > stepIndex ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildUploadButton(String docKey) {
    return CBButton(
      text: _documents[docKey] == null ? '拍照/上傳' : '重新上傳',
      onPressed: () => _handleUpload(docKey),
      icon: Icons.camera_alt_outlined,
      variant: _documents[docKey] == null
          ? CBButtonVariant.primary
          : CBButtonVariant.secondary,
      size: CBButtonSize.medium,
    );
  }

  Future<void> _handleUpload(String docKey) async {
    // TODO: Implement camera/file picker
    // For web/dev: file picker
    // For mobile: camera
    CBToast.show(
      context: context,
      message: '拍照/上傳功能開發中（Storage 整合待完成）',
      type: CBToastType.info,
    );

    // Simulate upload
    setState(() {
      _documents[docKey] = 'mock_${docKey}_url';
    });
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Validate name
      if (_nameController.text.trim().isEmpty) {
        CBToast.show(
          context: context,
          message: '請輸入真實姓名',
          type: CBToastType.error,
        );
        return;
      }
    } else if (_currentStep == 7) {
      // Validate bank book and account
      if (_documents['bank_book'] == null) {
        CBToast.show(
          context: context,
          message: '請上傳銀行帳簿照片',
          type: CBToastType.error,
        );
        return;
      }
      if (_bankAccountController.text.trim().isEmpty) {
        CBToast.show(
          context: context,
          message: '請輸入銀行帳號',
          type: CBToastType.error,
        );
        return;
      }
    } else {
      // Validate document upload
      final requiredDocs = {
        1: 'id_front',
        2: 'id_back',
        3: 'selfie',
        4: 'driver_license',
        5: 'vehicle_registration',
        6: 'police_record',
        8: 'logo_bag',
      };

      if (requiredDocs.containsKey(_currentStep)) {
        final docKey = requiredDocs[_currentStep]!;
        if (_documents[docKey] == null) {
          CBToast.show(
            context: context,
            message: '請先上傳此證件',
            type: CBToastType.error,
          );
          return;
        }
      }
    }

    if (_currentStep < 8) {
      setState(() => _currentStep++);
    } else {
      // Submit all documents
      _submitKYC();
    }
  }

  Future<void> _submitKYC() async {
    // TODO: Upload to Supabase Storage and update courier profile
    CBToast.show(
      context: context,
      message: 'KYC 資料提交成功（開發中）',
      type: CBToastType.success,
    );

    // Navigate to CurrentOrders
    if (mounted) {
      context.go('/current-orders');
    }
  }
}

