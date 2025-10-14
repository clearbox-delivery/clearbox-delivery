import 'package:flutter/material.dart';
import 'package:core_ui/src/theme/design_tokens.dart';

/// ClearBox Tabs Component
/// [UI_GUIDELINES.md] Underline style tabs with brand color indicator
class CBTabs extends StatelessWidget {
  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const CBTabs({
    super.key,
    required this.labels,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignTokens.border, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.sp3,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? DesignTokens.brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? DesignTokens.textPrimary
                        : DesignTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

