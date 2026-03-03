import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/ingredient.dart';

/// Calorie Donut Chart Widget
/// Displays a donut chart showing calorie distribution by ingredient category
class CalorieDonutChart extends StatelessWidget {
  final List<Ingredient> ingredients;

  const CalorieDonutChart({
    super.key,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate calorie breakdown by category
    final categoryCalories = <IngredientCategory, double>{};
    double totalCalories = 0;

    for (final ingredient in ingredients) {
      final calories = ingredient.nutrition?.totalCalories ?? 0;
      if (calories > 0) {
        final category = ingredient.category;
        categoryCalories[category] = (categoryCalories[category] ?? 0) + calories;
        totalCalories += calories;
      }
    }

    if (totalCalories == 0) {
      return const Center(
        child: Text('No calorie data available'),
      );
    }

    // Sort categories by calorie count
    final sortedCategories = categoryCalories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _DonutChartPainter(
        categoryCalories: sortedCategories,
        totalCalories: totalCalories,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${totalCalories.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              'kcal',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ingredients.length} ingredients',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for Donut Chart
class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<IngredientCategory, double>> categoryCalories;
  final double totalCalories;

  _DonutChartPainter({
    required this.categoryCalories,
    required this.totalCalories,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final innerRadius = radius * 0.65;

    double startAngle = -math.pi / 2; // Start from top

    for (final entry in categoryCalories) {
      final category = entry.key;
      final calories = entry.value;
      final sweepAngle = (calories / totalCalories) * 2 * math.pi;

      // Draw segment
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.butt;

      // Create gradient for the segment
      final rect = Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2);
      paint.shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          category.color.withOpacity(0.8),
          category.color.withOpacity(0.6),
        ],
        tileMode: TileMode.decal,
      ).createShader(rect);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (background)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.categoryCalories != categoryCalories ||
        oldDelegate.totalCalories != totalCalories;
  }
}
