import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:customer_app/features/discovery/presentation/store_recommendations_page.dart';

/// Categories Overlay with bounce animation
/// [customer_app_whitepaper.md Section 4.1]
/// Drops from top with bounce effect
class CategoriesOverlay extends ConsumerStatefulWidget {
  const CategoriesOverlay({super.key});

  @override
  ConsumerState<CategoriesOverlay> createState() => _CategoriesOverlayState();
}

class _CategoriesOverlayState extends ConsumerState<CategoriesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  final List<FoodCategory> _categories = [
    FoodCategory('便當/自助餐類', 45),
    FoodCategory('麵食類', 38),
    FoodCategory('鍋貼/水餃類', 22),
    FoodCategory('炒飯/炒麵類', 31),
    FoodCategory('雞肉飯/鴨肉飯/肉燥飯類', 28),
    FoodCategory('速食/炸物類', 19),
    FoodCategory('飲料類', 52),
    FoodCategory('甜點類', 25),
    FoodCategory('宵夜/早餐類', 33),
    FoodCategory('異國料理類', 27),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Motion token: smooth
    );

    // Bounce effect: elastic curve simulates ball drop
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Bounce effect
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryTap(FoodCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoreRecommendationsPage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort by ad count descending
    final sortedCategories = [..._categories]
      ..sort((a, b) => b.adCount.compareTo(a.adCount));

    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: DesignTokens.bg,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(DesignTokens.radiusLg),
              bottomRight: Radius.circular(DesignTokens.radiusLg),
            ),
            boxShadow: [DesignTokens.shadowLg],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.sp6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '今天想吃什麼？',
                        style: TextStyle(
                          fontSize: DesignTokens.fs2xl,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: DesignTokens.textMuted,
                      ),
                    ],
                  ),
                ),

                // Categories grid (2 per row)
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.sp6,
                      vertical: DesignTokens.sp4,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: DesignTokens.sp4,
                      mainAxisSpacing: DesignTokens.sp4,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final category = sortedCategories[index];
                      return _buildCategoryCard(category);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(FoodCategory category) {
    return CBCard(
      onTap: () => _onCategoryTap(category),
      child: Center(
        child: Text(
          category.name,
          style: const TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.w500,
            color: DesignTokens.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Food category model (temporary, can move to domain)
class FoodCategory {
  final String name;
  final int adCount; // Number of merchants advertising in this category

  FoodCategory(this.name, this.adCount);
}

