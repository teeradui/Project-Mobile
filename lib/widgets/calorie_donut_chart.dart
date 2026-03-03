import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Calorie Donut Chart Widget
/// Displays a donut chart showing calorie distribution by ingredient category
/// Supports both Map<String, int> breakdown and legacy List<Ingredient>
class CalorieDonutChart extends StatelessWidget {
  final Map<String, int>? calorieBreakdown;
  final int? totalCalories;
  final double size;

  // Legacy support - kept for backward compatibility
  final List<dynamic>? ingredients;

  const CalorieDonutChart({
    super.key,
    this.calorieBreakdown,
    this.totalCalories,
    this.size = 150,
    this.ingredients,
  }) : assert(
          calorieBreakdown != null || ingredients != null,
          'Either calorieBreakdown or ingredients must be provided',
        );

  @override
  Widget build(BuildContext context) {
    // Calculate calorie breakdown by category
    final categoryCalories = <_CategoryData, double>{};
    double totalCals = 0;

    if (calorieBreakdown != null) {
      // Use provided breakdown
      totalCals = (totalCalories ?? 0).toDouble();
      calorieBreakdown!.forEach((category, calories) {
        final catData = _getCategoryData(category);
        final currentCalories = categoryCalories[catData] ?? 0.0;
        categoryCalories[catData] = currentCalories + calories.toDouble();
      });
    }

    if (totalCals == 0 && categoryCalories.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text(
            'No calorie\ndata',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Sort categories by calorie count
    final sortedCategories = categoryCalories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DonutChartPainter(
          categoryCalories: sortedCategories,
          totalCalories: totalCals,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${totalCals.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get category data (color and label) for a category name
  _CategoryData _getCategoryData(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'protein':
        return _CategoryData('Protein', const Color(0xFFFF6B6B));
      case 'carbs':
        return _CategoryData('Carbs', const Color(0xFFFFD93D));
      case 'vegetables':
        return _CategoryData('Vegetables', const Color(0xFF6BCB77));
      case 'dairy':
        return _CategoryData('Dairy', const Color(0xFF4D96FF));
      default:
        return _CategoryData('Others', const Color(0xFF9CA3AF));
    }
  }
}

/// Category data class
class _CategoryData {
  final String label;
  final Color color;

  const _CategoryData(this.label, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CategoryData &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}

/// Custom Painter for Donut Chart
class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<_CategoryData, double>> categoryCalories;
  final double totalCalories;

  _DonutChartPainter({
    required this.categoryCalories,
    required this.totalCalories,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final innerRadius = radius * 0.65;

    // Handle edge case: no calories or empty data
    if (totalCalories <= 0 || categoryCalories.isEmpty) {
      // Draw empty chart with gray circle
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..color = Colors.grey.withValues(alpha: 0.3);
      canvas.drawCircle(
        center,
        (radius + innerRadius) / 2,
        paint,
      );
      return;
    }

    double startAngle = -math.pi / 2; // Start from top

    for (final entry in categoryCalories) {
      final category = entry.key;
      final calories = entry.value;
      final sweepAngle = (calories / totalCalories) * 2 * math.pi;

      // Skip invalid segments
      if (sweepAngle <= 0 || !sweepAngle.isFinite) continue;

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
          category.color.withValues(alpha: 0.8),
          category.color.withValues(alpha: 0.6),
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

/// Calorie Legend Widget
/// Shows the color legend for the donut chart categories
class CalorieLegend extends StatelessWidget {
  final Map<String, int> breakdown;

  const CalorieLegend({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: breakdown.entries.map((entry) {
        final color = _getCategoryColor(entry.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key}: ${entry.value} kcal',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'protein':
        return const Color(0xFFFF6B6B);
      case 'carbs':
        return const Color(0xFFFFD93D);
      case 'vegetables':
        return const Color(0xFF6BCB77);
      case 'dairy':
        return const Color(0xFF4D96FF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
