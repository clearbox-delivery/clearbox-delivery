import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:merchant_app/features/profile/presentation/initial_store_setup/step1_store_info.dart';
import 'package:merchant_app/features/profile/presentation/initial_store_setup/step2_business_registration.dart';
import 'package:merchant_app/features/profile/presentation/initial_store_setup/step3_food_registration.dart';
import 'package:merchant_app/features/profile/presentation/initial_store_setup/step4_menu_upload.dart';
import 'package:merchant_app/features/profile/presentation/initial_store_setup/step5_bankbook.dart';

/// Initial Store Setup Coordinator (5 steps)
/// [merchant_app_whitepaper.md Section 2]
class InitialStoreSetupCoordinator extends ConsumerStatefulWidget {
  const InitialStoreSetupCoordinator({super.key});

  @override
  ConsumerState<InitialStoreSetupCoordinator> createState() =>
      _InitialStoreSetupCoordinatorState();
}

class _InitialStoreSetupCoordinatorState
    extends ConsumerState<InitialStoreSetupCoordinator> {
  int _currentStep = 0;
  final Map<String, dynamic> _formData = {};

  void _nextStep(Map<String, dynamic> stepData) {
    setState(() {
      _formData.addAll(stepData);
      if (_currentStep < 4) {
        _currentStep++;
      } else {
        _completeSetup();
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeSetup() async {
    // Save all data to Supabase
    // Mark merchant initial_setup_complete = true
    // Navigate to CurrentOrders
    if (mounted && context.mounted) {
      CBToast.show(
        context: context,
        message: '設定完成',
        type: CBToastType.success,
      );
      context.go('/current-orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text('初始設定 ${_currentStep + 1}/5'),
        automaticallyImplyLeading: _currentStep > 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          Step1StoreInfo(onNext: _nextStep),
          Step2BusinessRegistration(onNext: _nextStep),
          Step3FoodRegistration(onNext: _nextStep),
          Step4MenuUpload(onNext: _nextStep),
          Step5Bankbook(onNext: _nextStep),
        ],
      ),
    );
  }
}

