import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:domain/domain.dart';
import 'heat_paint_utils.dart';

/// Heat Map Widget - Full k=40 grid visualization with CustomPaint
/// [courier_app_whitepaper.md Section 4.1]
/// [REQ-COU-HEAT-002] Display full k=40 heat map with updates
class HeatMapWidget extends StatefulWidget {
  final String? centerH3;
  final Map<String, double> heatValues; // h3_cell -> heat (0..1)
  final int k; // Range (default 40)
  final Function(String h3Cell)? onCellTap;

  const HeatMapWidget({
    super.key,
    this.centerH3,
    required this.heatValues,
    this.k = 40,
    this.onCellTap,
  });

  @override
  State<HeatMapWidget> createState() => _HeatMapWidgetState();
}

class _HeatMapWidgetState extends State<HeatMapWidget> {
  Timer? _updateTimer;
  Map<String, double> _currentHeat = {};
  Map<String, double> _previousHeat = {};

  @override
  void initState() {
    super.initState();
    _currentHeat = Map.from(widget.heatValues);
    _previousHeat = Map.from(widget.heatValues);

    // Start 30-second update timer
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateHeatWithEMA();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(HeatMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heatValues != oldWidget.heatValues) {
      _updateHeatWithEMA();
    }
  }

  void _updateHeatWithEMA() {
    setState(() {
      final newHeat = <String, double>{};
      for (final entry in widget.heatValues.entries) {
        final h3 = entry.key;
        final newValue = entry.value;
        final previousValue = _previousHeat[h3] ?? newValue;

        // Apply EMA smoothing (alpha = 0.2)
        newHeat[h3] = HeatMath.ema(
          previous: previousValue,
          current: newValue,
          alpha: 0.2,
        );
      }
      _previousHeat = Map.from(_currentHeat);
      _currentHeat = newHeat;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.centerH3 == null || _currentHeat.isEmpty) {
      return _buildPlaceholder();
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: DesignTokens.bg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Stack(
        children: [
          // Full k=40 heat grid with CustomPaint
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: GestureDetector(
              onTapUp: (details) => _handleTap(details.localPosition),
              child: CustomPaint(
                size: Size.infinite,
                painter: HeatMapPainter(
                  heatValues: _currentHeat,
                  k: widget.k,
                  cellSize: 3.0, // Small size for k=40 to fit
                ),
              ),
            ),
          ),

          // Legend
          Positioned(
            top: DesignTokens.sp2,
            right: DesignTokens.sp2,
            child: _buildLegend(),
          ),

          // Center indicator
          const Center(
            child: Icon(
              Icons.my_location,
              size: 24,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset localPosition) {
    if (widget.onCellTap == null) return;

    // Convert tap position to canvas-relative coordinates
    // (canvas center is widget center)
    final size = context.size;
    if (size == null) return;

    final centerOffset = Offset(size.width / 2, size.height / 2);
    final tapOffset = localPosition - centerOffset;

    // Convert to hex coordinates
    final (q, r) = HeatPaintUtils.canvasToH3Offset(
      point: tapOffset,
      cellSize: 3.0,
    );

    // Find corresponding h3 cell from heatValues
    // (In real scenario, need to map (q,r) to actual h3 string)
    // For now, trigger callback with mock h3
    widget.onCellTap!('h3_${q}_$r');
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300,
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

/// CustomPainter for heat map hexagonal grid
class HeatMapPainter extends CustomPainter {
  final Map<String, double> heatValues;
  final int k;
  final double cellSize;

  HeatMapPainter({
    required this.heatValues,
    required this.k,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Generate k-ring cells
    final cells = HeatPaintUtils.generateKRing(k);

    // Canvas center
    final center = Offset(size.width / 2, size.height / 2);

    // Draw each hex cell
    for (final (q, r) in cells) {
      // Get heat value (default 0 if not in map)
      final cellKey = 'h3_${q}_$r'; // Mock key format
      final heat = heatValues[cellKey] ?? 0.0;

      // Convert to canvas coordinates
      final cellOffset = HeatPaintUtils.h3OffsetToCanvas(
        q: q,
        r: r,
        cellSize: cellSize,
      );
      final cellCenter = center + cellOffset;

      // Draw hexagon
      _drawHexagon(canvas, cellCenter, cellSize, heat);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, double heat) {
    final paint = Paint()
      ..color = HeatPaintUtils.heatToColor(heat)
      ..style = PaintingStyle.fill;

    // Hexagon vertices (flat-top)
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * 3.14159 / 180;
      final x = center.dx + size * (angle).cos();
      final y = center.dy + size * (angle).sin();
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw border (subtle)
    final borderPaint = Paint()
      ..color = DesignTokens.border.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(HeatMapPainter oldDelegate) {
    return heatValues != oldDelegate.heatValues ||
        k != oldDelegate.k ||
        cellSize != oldDelegate.cellSize;
  }
}

/// Bottom sheet to display cell statistics on tap
class HeatCellSheet extends StatelessWidget {
  final String h3Cell;
  final int waitingOrders;
  final int activeCouriers;

  const HeatCellSheet({
    super.key,
    required this.h3Cell,
    required this.waitingOrders,
    required this.activeCouriers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.sp4),
      decoration: const BoxDecoration(
        color: DesignTokens.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '區域統計',
            style: TextStyle(
              fontSize: DesignTokens.fsLg,
              fontWeight: FontWeight.bold,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.sp2),
          Text(
            'H3 Cell: $h3Cell',
            style: const TextStyle(
              fontSize: DesignTokens.fsSm,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.sp3),
          _buildStatRow('等待訂單', waitingOrders.toString(), Icons.shopping_bag),
          const SizedBox(height: DesignTokens.sp2),
          _buildStatRow('活躍外送員', activeCouriers.toString(), Icons.delivery_dining),
          const SizedBox(height: DesignTokens.sp3),
          CBButton(
            label: '關閉',
            onPressed: () => Navigator.of(context).pop(),
            variant: CBButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DesignTokens.textSecondary),
        const SizedBox(width: DesignTokens.sp2),
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fsMd,
            color: DesignTokens.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: DesignTokens.fsLg,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
