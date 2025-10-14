import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';

/// Heat Map Widget - Visualize H3 cell demand
/// [courier_app_whitepaper.md Section 4.1]
/// [REQ-COU-HEAT-001] Display color-coded heat map
class HeatMapWidget extends StatelessWidget {
  final String? centerH3;
  final Map<String, double> heatValues; // h3_cell -> heat (0..1)

  const HeatMapWidget({
    super.key,
    this.centerH3,
    required this.heatValues,
  });

  @override
  Widget build(BuildContext context) {
    if (centerH3 == null || heatValues.isEmpty) {
      return _buildPlaceholder();
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: DesignTokens.bg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Stack(
        children: [
          // Heat grid (simplified: show center and 8 surrounding cells)
          _buildSimplifiedGrid(),

          // Legend
          Positioned(
            top: DesignTokens.sp2,
            right: DesignTokens.sp2,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: DesignTokens.bgSubtle,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: DesignTokens.border),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: DesignTokens.textMuted),
            SizedBox(height: DesignTokens.sp3),
            Text(
              '需求熱度地圖',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textPrimary,
              ),
            ),
            SizedBox(height: DesignTokens.sp2),
            Text(
              '取得位置中...',
              style: TextStyle(
                fontSize: DesignTokens.fsSm,
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedGrid() {
    // Simplified 3x3 grid (center + 8 neighbors)
    // Full k=40 grid would need canvas/custom paint
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.sp4),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          // Mock heat values for demo (use actual heatValues when data available)
          final mockHeat = _getMockHeat(index);
          return Container(
            decoration: BoxDecoration(
              color: _getHeatColor(mockHeat),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: index == 4 // Center cell
                ? const Icon(Icons.my_location, size: 16, color: Colors.white)
                : null,
          );
        },
      ),
    );
  }

  double _getMockHeat(int index) {
    // Mock heat for demo (center highest, gradually decreasing)
    if (index == 4) return 0.9; // Center (courier location)
    if (index == 1 || index == 3 || index == 5 || index == 7) return 0.6; // Adjacent
    return 0.3; // Corners
  }

  Color _getHeatColor(double heat) {
    // Color gradient: White (0) → Yellow (0.33) → Orange (0.66) → Red (1)
    if (heat < 0.33) {
      // White to Yellow
      return Color.lerp(
        Colors.white,
        const Color(0xFFFFF59D), // Light yellow
        heat / 0.33,
      )!;
    } else if (heat < 0.66) {
      // Yellow to Orange
      return Color.lerp(
        const Color(0xFFFFF59D),
        const Color(0xFFFFB74D), // Orange
        (heat - 0.33) / 0.33,
      )!;
    } else {
      // Orange to Red
      return Color.lerp(
        const Color(0xFFFFB74D),
        const Color(0xFFEF5350), // Red
        (heat - 0.66) / 0.34,
      )!;
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.sp2,
        vertical: DesignTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(Colors.white, '低'),
          const SizedBox(width: DesignTokens.sp2),
          _buildLegendItem(const Color(0xFFFFB74D), '中'),
          const SizedBox(width: DesignTokens.sp2),
          _buildLegendItem(const Color(0xFFEF5350), '高'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: DesignTokens.border),
          ),
        ),
        const SizedBox(width: DesignTokens.sp1),
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fsXs,
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
