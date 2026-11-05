import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MetricBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isPositive;

  const MetricBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isPositive ? AppColors.accent : AppColors.expense);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

