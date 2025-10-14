import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/features/address/presentation/address_edit_dialog.dart';

/// Addresses Management Page
/// [customer_app_whitepaper.md Section 6]
class AddressesPage extends ConsumerStatefulWidget {
  const AddressesPage({super.key});

  @override
  ConsumerState<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends ConsumerState<AddressesPage> {
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
          message: '載入失敗: $e',
          type: CBToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('地址管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const AddressEditDialog(),
              );
              if (result == true) _loadAddresses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CBLoadingIndicator())
          : _addresses.isEmpty
              ? const CBEmptyState(
                  icon: Icons.location_on_outlined,
                  title: '尚無地址',
                  description: '點擊右上角新增地址',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(DesignTokens.sp6),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DesignTokens.sp4),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return _buildAddressCard(address);
                  },
                ),
    );
  }

  Widget _buildAddressCard(UserAddress address) {
    return CBCard(
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
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AddressEditDialog(address: address),
                  );
                  if (result == true) _loadAddresses();
                },
                color: DesignTokens.brand,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () async {
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
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.danger,
                          ),
                          child: const Text('刪除'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref
                          .read(addressServiceProvider)
                          .deleteAddress(address.id);
                      _loadAddresses();
                      if (mounted && context.mounted) {
                        CBToast.show(
                          context: context,
                          message: '已刪除',
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
                },
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
        ],
      ),
    );
  }
}

