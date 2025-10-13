import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:customer_app/features/merchants/presentation/menu_browse_page.dart';

/// 商家列表页面
/// [REQ-CUST-SORT-001] 推荐餐厅排序
class MerchantListPage extends ConsumerWidget {
  const MerchantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('選擇商家'),
      ),
      body: FutureBuilder<List<Merchant>>(
        future: _loadMerchants(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CBLoadingIndicator());
          }

          if (snapshot.hasError) {
            return CBErrorState(
              title: '載入失敗',
              description: snapshot.error.toString(),
            );
          }

          final merchants = snapshot.data ?? [];

          if (merchants.isEmpty) {
            return const CBEmptyState(
              icon: Icons.store_outlined,
              title: '附近沒有商家',
              description: '請稍後再試',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: merchants.length,
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              return _MerchantCard(
                merchant: merchant,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuBrowsePage(merchant: merchant),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Merchant>> _loadMerchants(WidgetRef ref) async {
    final supabase = ref.read(supabaseProvider);
    final response = await supabase
        .from('merchants')
        .select()
        .eq('is_open', true);

    return (response as List)
        .map((json) => Merchant.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

class _MerchantCard extends StatelessWidget {
  final Merchant merchant;
  final VoidCallback onTap;

  const _MerchantCard({
    required this.merchant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CBCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: DesignTokens.sp3),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: DesignTokens.bgSubtle,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(
              Icons.store,
              size: 40,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(width: DesignTokens.sp4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.name,
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.sp2),
                Text(
                  merchant.address,
                  style: const TextStyle(
                    fontSize: DesignTokens.fsSm,
                    color: DesignTokens.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: DesignTokens.textMuted,
          ),
        ],
      ),
    );
  }
}

