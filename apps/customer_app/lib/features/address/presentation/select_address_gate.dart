import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/features/address/presentation/address_edit_dialog.dart';
import 'package:customer_app/providers/selected_address_provider.dart';

/// Address Selection Gate
/// [customer_app_whitepaper.md Section 2]
/// Every app entry requires address selection
class SelectAddressGate extends ConsumerStatefulWidget {
  const SelectAddressGate({super.key});

  @override
  ConsumerState<SelectAddressGate> createState() => _SelectAddressGateState();
}

class _SelectAddressGateState extends ConsumerState<SelectAddressGate> {
  List<UserAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final addressService = ref.read(addressServiceProvider);
      final addresses = await addressService.getUserAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CBToast.show(
          context: context,
          message: '載入地址失敗: $e',
          type: CBToastType.error,
        );
      }
    }
  }

  void _selectAddress(UserAddress address) {
    // Store selected address in state management
    ref.read(selectedAddressProvider.notifier).selectAddress(address);

    // Navigate to NewOrder with flag to auto-show categories
    // [customer_app_whitepaper.md Section 4.1] 預設顯示「今天想吃什麼？」
    context.go('/new-order', extra: {'autoShowCategories': true});
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddressEditDialog(),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _showEditDialog(UserAddress address) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddressEditDialog(address: address),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _deleteAddress(UserAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除地址'),
        content: Text('確定要刪除「${address.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.danger),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(addressServiceProvider).deleteAddress(address.id);
        _loadAddresses();
        if (mounted && context.mounted) {
          CBToast.show(
            context: context,
            message: '已刪除地址',
            type: CBToastType.success,
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          CBToast.show(
            context: context,
            message: '刪除失敗: $e',
            type: CBToastType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('選擇地址'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.sp6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '請選擇本次訂餐地址',
                        style: TextStyle(
                          fontSize: DesignTokens.fsXl,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.sp2),
                      const Text(
                        '您可以在此頁編輯地址',
                        style: TextStyle(
                          fontSize: DesignTokens.fsSm,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _addresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '尚無地址',
                                style: TextStyle(
                                  fontSize: DesignTokens.fsLg,
                                  color: DesignTokens.textMuted,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.sp4),
                              CBButton(
                                text: '新增地址',
                                onPressed: _showAddDialog,
                                icon: Icons.add,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.sp6,
                          ),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: DesignTokens.sp4),
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            return _buildAddressCard(address);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.sp6),
                  child: CBButton(
                    text: '新增地址',
                    onPressed: _showAddDialog,
                    icon: Icons.add,
                    type: CBButtonType.secondary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddressCard(UserAddress address) {
    return CBCard(
      onTap: () => _selectAddress(address),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.name,
                  style: const TextStyle(
                    fontSize: DesignTokens.fsLg,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditDialog(address),
                color: DesignTokens.brand,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _deleteAddress(address),
                color: DesignTokens.danger,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.sp2),
          Text(
            address.address,
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textSecondary,
            ),
          ),
          if (address.googleMapsLink.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.sp2),
            Text(
              'Google Maps',
              style: const TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.brand,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

