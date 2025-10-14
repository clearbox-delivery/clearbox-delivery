import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:domain/domain.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:geo_h3/geo_h3.dart';
import 'package:latlong2/latlong.dart';
import 'package:customer_app/features/merchants/presentation/menu_browse_page.dart';
import 'package:customer_app/providers/selected_address_provider.dart';

/// 商家列表页面
/// [REQ-CUST-SORT-001] H3 ring k=40 + S sorting
/// [customer_app_whitepaper.md Section 4.4, 4.5]
class MerchantListPage extends ConsumerWidget {
  const MerchantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAddress = ref.watch(selectedAddressProvider);

    if (selectedAddress == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bg,
        appBar: AppBar(title: const Text('選擇商家')),
        body: const CBErrorState(
          title: '請先選擇地址',
          description: '返回並選擇配送地址',
        ),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('選擇商家'),
      ),
      body: FutureBuilder<List<_MerchantWithScore>>(
        future: _loadAndSortMerchants(ref, selectedAddress),
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
              description: '此區域暫無營業店家',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.sp4),
            itemCount: merchants.length,
            itemBuilder: (context, index) {
              final item = merchants[index];
              return _MerchantCard(
                merchant: item.merchant,
                score: item.score,
                distance: item.distance,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MenuBrowsePage(merchant: item.merchant),
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

  Future<List<_MerchantWithScore>> _loadAndSortMerchants(
    WidgetRef ref,
    UserAddress selectedAddress,
  ) async {
    final supabase = ref.read(supabaseProvider);
    final h3Service = H3Service();

    // Get customer location and H3 cell
    final customerLoc = LatLng(selectedAddress.latitude, selectedAddress.longitude);
    final customerH3 = h3Service.latLngToCell(customerLoc, 10);

    // Generate k-ring of 40
    // [customer_app_whitepaper.md Section 4.5] k=40 ring
    final ring = h3Service.gridDisk(customerH3, 40);

    // Fetch all merchants
    final response = await supabase
        .from('merchants')
        .select()
        .eq('is_open', true);

    final allMerchants = (response as List)
        .map((json) => Merchant.fromJson(json as Map<String, dynamic>))
        .toList();

    // Filter merchants within ring
    final inRingMerchants = allMerchants.where((m) {
      return ring.contains(m.h3Cell);
    }).toList();

    if (inRingMerchants.isEmpty) {
      return [];
    }

    // Fetch weekly meal counts for S calculation
    final weeklyMealCounts = await supabase
        .from('merchants')
        .select('id, weekly_meal_count, latitude, longitude')
        .eq('is_open', true)
        .then((res) => (res as List).map((json) => json as Map<String, dynamic>).toList());

    final mealCountMap = <String, int>{};
    final coordsMap = <String, LatLng>{};
    for (final item in weeklyMealCounts) {
      final id = item['id'] as String;
      mealCountMap[id] = item['weekly_meal_count'] as int? ?? 0;
      final lat = (item['latitude'] as num?)?.toDouble() ?? 25.0330;
      final lng = (item['longitude'] as num?)?.toDouble() ?? 121.5654;
      coordsMap[id] = LatLng(lat, lng);
    }

    // Calculate P95 and min/max for meal counts
    final counts = mealCountMap.values.toList();
    final p95 = MerchantSortingCalculator.calculateP95(counts);
    final cappedCounts = counts.map((c) => c > p95 ? p95 : c).toList();
    final minCount = cappedCounts.isEmpty ? 0 : cappedCounts.reduce((a, b) => a < b ? a : b);
    final maxCount = cappedCounts.isEmpty ? 0 : cappedCounts.reduce((a, b) => a > b ? a : b);

    // Calculate S score for each merchant
    final merchantsWithScore = inRingMerchants.map((m) {
      final merchantLoc = coordsMap[m.id] ?? LatLng(25.0330, 121.5654);
      final distance = DistanceCalculator.calculateDistance(customerLoc, merchantLoc);
      final weeklyCount = mealCountMap[m.id] ?? 0;
      final cappedCount = weeklyCount > p95 ? p95 : weeklyCount;

      final score = MerchantSortingCalculator.calculateScore(
        customerLocation: customerLoc,
        merchantLocation: merchantLoc,
        weeklyMealCount: cappedCount,
        maxMealCount: maxCount,
        minMealCount: minCount,
      );

      return _MerchantWithScore(
        merchant: m,
        score: score,
        distance: distance,
      );
    }).toList();

    // Sort by S descending
    merchantsWithScore.sort((a, b) => b.score.compareTo(a.score));

    return merchantsWithScore;
  }
}

class _MerchantWithScore {
  final Merchant merchant;
  final double score;
  final double distance;

  _MerchantWithScore({
    required this.merchant,
    required this.score,
    required this.distance,
  });
}

class _MerchantCard extends StatelessWidget {
  final Merchant merchant;
  final double score;
  final double distance;
  final VoidCallback onTap;

  const _MerchantCard({
    required this.merchant,
    required this.score,
    required this.distance,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.sp2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: DesignTokens.textMuted,
                    ),
                    const SizedBox(width: DesignTokens.sp1),
                    Text(
                      '${distance.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.sp3),
                    Text(
                      'S: ${score.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: DesignTokens.fsSm,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
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
