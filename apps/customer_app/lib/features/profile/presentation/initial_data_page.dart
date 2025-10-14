import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_client/supabase_client.dart';

/// Initial Data Page (Mandatory on first login)
/// [customer_app_whitepaper.md Section 2]
/// Step 1: Nickname input
/// Step 2: First address
class InitialDataPage extends ConsumerStatefulWidget {
  const InitialDataPage({super.key});

  @override
  ConsumerState<InitialDataPage> createState() => _InitialDataPageState();
}

class _InitialDataPageState extends ConsumerState<InitialDataPage> {
  final _nicknameController = TextEditingController();
  final _addressNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapsLinkController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _addressNameController.dispose();
    _addressController.dispose();
    _mapsLinkController.dispose();
    super.dispose();
  }

  Future<void> _handleNicknameSubmit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      if (context.mounted) {
        CBToast.show(
          context: context,
          message: '請輸入暱稱',
          type: CBToastType.error,
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('未登入');

      // Save nickname to user_profiles
      await ref.read(supabaseProvider).from('user_profiles').upsert({
        'id': userId,
        'nickname': nickname,
      });

      setState(() {
        _currentStep = 1;
        _isLoading = false;
      });
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

  Future<void> _handleAddressSubmit() async {
    final name = _addressNameController.text.trim();
    final address = _addressController.text.trim();
    final mapsLink = _mapsLinkController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      if (context.mounted) {
        CBToast.show(
          context: context,
          message: '請填寫地址名稱與地址',
          type: CBToastType.error,
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final addressService = ref.read(addressServiceProvider);
      await addressService.createAddress(
        name: name,
        address: address,
        googleMapsLink: mapsLink,
      );

      if (mounted && context.mounted) {
        // Mark initial setup complete
        final userId = ref.read(authServiceProvider).currentUserId;
        await ref.read(supabaseProvider).from('user_profiles').update({
          'initial_setup_complete': true,
        }).eq('id', userId!);

        CBToast.show(
          context: context,
          message: '設定完成',
          type: CBToastType.success,
        );

        // Navigate to address gate
        context.go('/address-gate');
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
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('初始設定'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.sp6),
        child: _currentStep == 0 ? _buildNicknameStep() : _buildAddressStep(),
      ),
    );
  }

  Widget _buildNicknameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '請輸入您的暱稱',
          style: TextStyle(
            fontSize: DesignTokens.fs2xl,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp2),
        const Text(
          '這個暱稱會顯示給店家和外送員',
          style: TextStyle(
            fontSize: DesignTokens.fsSm,
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp6),
        CBInput(
          label: '暱稱',
          controller: _nicknameController,
          hintText: '輸入暱稱',
        ),
        const SizedBox(height: DesignTokens.sp6),
        CBButton(
          text: '下一步',
          onPressed: _isLoading ? null : _handleNicknameSubmit,
          isLoading: _isLoading,
          size: CBButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '建立常用地址',
          style: TextStyle(
            fontSize: DesignTokens.fs2xl,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp2),
        const Text(
          '請新增至少一個地址以繼續使用',
          style: TextStyle(
            fontSize: DesignTokens.fsSm,
            color: DesignTokens.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.sp6),
        CBInput(
          label: '地址名稱',
          controller: _addressNameController,
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
        CBButton(
          text: '完成設定',
          onPressed: _isLoading ? null : _handleAddressSubmit,
          isLoading: _isLoading,
          size: CBButtonSize.large,
        ),
      ],
    );
  }
}

