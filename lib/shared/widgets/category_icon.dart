import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class CategoryIconWidget extends StatelessWidget {
  final String category;
  final double size;
  final double iconSize;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final catItem = AppConstants.getCategory(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: catItem.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: Icon(
          catItem.icon,
          size: iconSize,
          color: catItem.color,
        ),
      ),
    );
  }
}

