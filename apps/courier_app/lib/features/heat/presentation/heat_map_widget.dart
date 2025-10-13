import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:geo_h3/geo_h3.dart';
import 'dart:math' as math;

/// H3 供需热度地图组件
/// [REQ-COU-HEAT-001] 热度 = 订单数 / (1 + 外送员数)
class HeatMapWidget extends ConsumerWidget {
  final String currentH3Cell;

  const HeatMapWidget({
    super.key,
    required this.currentH3Cell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<H3Heat>>(
      future: _loadHeatData(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CBLoadingIndicator();
        }

        if (snapshot.hasError) {
          return const Text(
            '熱度資料載入失敗',
            style: TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.danger,
            ),
          );
        }

        final heatData = snapshot.data ?? [];
        final maxHeat = heatData.isEmpty
            ? 1.0
            : heatData.map((h) => h.heatScore).reduce(math.max);

        return CBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '需求熱度',
                style: TextStyle(
                  fontSize: DesignTokens.fsMd,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.sp4),

              // 热度图例
              Row(
                children: [
                  _buildLegendItem('低', const Color(0xFFFEF3C7)),
                  const SizedBox(width: DesignTokens.sp3),
                  _buildLegendItem('中', const Color(0xFFFED7AA)),
                  const SizedBox(width: DesignTokens.sp3),
                  _buildLegendItem('高', const Color(0xFFFCA5A5)),
                ],
              ),
              const SizedBox(height: DesignTokens.sp4),

              // 热度网格 (简化版本 - 显示附近几个格子)
              SizedBox(
                height: 120,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: math.min(heatData.length, 15),
                  itemBuilder: (context, index) {
                    if (index >= heatData.length) {
                      return const SizedBox();
                    }

                    final heat = heatData[index];
                    final normalizedHeat = maxHeat > 0
                        ? heat.heatScore / maxHeat
                        : 0.0;

                    return Container(
                      decoration: BoxDecoration(
                        color: _getHeatColor(normalizedHeat),
                        borderRadius: BorderRadius.circular(4),
                        border: heat.h3Cell == currentH3Cell
                            ? Border.all(color: DesignTokens.brand, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          heat.heatScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: DesignTokens.fsXs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: DesignTokens.sp1),
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fsSm,
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getHeatColor(double normalized) {
    if (normalized < 0.3) {
      return const Color(0xFFFEF3C7); // 黄色 (低)
    } else if (normalized < 0.7) {
      return const Color(0xFFFED7AA); // 橙色 (中)
    } else {
      return const Color(0xFFFCA5A5); // 红色 (高)
    }
  }

  Future<List<H3Heat>> _loadHeatData(WidgetRef ref) async {
    // 获取 k=40 范围内的格子
    final ring = H3Service.getVisibilityRing(currentH3Cell);
    final cells = ring.take(40).toList(); // 限制数量

    final locationService = ref.read(locationServiceProvider);
    return await locationService.getH3Heat(cells);
  }
}

