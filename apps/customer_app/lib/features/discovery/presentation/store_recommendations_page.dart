import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:customer_app/features/discovery/presentation/categories_overlay.dart';

/// Store Recommendations Page
/// [customer_app_whitepaper.md Section 4.2]
/// Shows stores by distance with recommended items
class StoreRecommendationsPage extends ConsumerStatefulWidget {
  final FoodCategory category;

  const StoreRecommendationsPage({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<StoreRecommendationsPage> createState() =>
      _StoreRecommendationsPageState();
}

class _StoreRecommendationsPageState
    extends ConsumerState<StoreRecommendationsPage> {
  // TODO: Fetch from Supabase based on category and distance
  final List<_StoreRecommendation> _mockStores = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: _mockStores.isEmpty
          ? const Center(
              child: CBEmptyState(
                message: '此類別暫無店家',
                icon: Icons.store_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.sp6),
              itemCount: _mockStores.length,
              separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp4),
              itemBuilder: (context, index) {
                final store = _mockStores[index];
                return _buildStoreCard(store);
              },
            ),
    );
  }

  Widget _buildStoreCard(_StoreRecommendation store) {
    return CBCard(
      onTap: () {
        // TODO: Navigate to store menu
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendation text format
          // [customer_app_whitepaper.md Section 4.2]
          Text(
            '「${store.storeName}」想向你推薦他們家的「${store.recommendedItem}」',
            style: const TextStyle(
              fontSize: DesignTokens.fsLg,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp3),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: DesignTokens.accent),
              const SizedBox(width: DesignTokens.sp1),
              Text(
                store.rating.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.sp4),
              const Icon(Icons.location_on, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: DesignTokens.sp1),
              Text(
                '${store.distance}m',
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
              if (store.hasDiscount) ...[
                const SizedBox(width: DesignTokens.sp4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.sp2,
                    vertical: DesignTokens.sp1,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: const Text(
                    '全店 85 折',
                    style: TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreRecommendation {
  final String storeName;
  final String recommendedItem;
  final double rating;
  final int distance;
  final bool hasDiscount;

  _StoreRecommendation({
    required this.storeName,
    required this.recommendedItem,
    required this.rating,
    required this.distance,
    this.hasDiscount = false,
  });
}

