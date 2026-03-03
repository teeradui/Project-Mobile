import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Calorie Donut Chart Widget
/// Displays a donut chart showing calorie breakdown by ingredient category
class CalorieDonutChart extends StatelessWidget {
  final Map<String, int> calorieBreakdown;
  final int totalCalories;
  final double size;

  const CalorieDonutChart({
    super.key,
    required this.calorieBreakdown,
    required this.totalCalories,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Donut chart
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              breakdown: calorieBreakdown,
              total: totalCalories,
            ),
          ),
          // Center text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalCalories',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'kcal',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: size * 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, int> breakdown;
  final int total;

  _DonutChartPainter({
    required this.breakdown,
    required this.total,
  });

  // Category colors
  static const Map<String, Color> categoryColors = {
    'Protein': Color(0xFFFF6B6B),
    'Carbs': Color(0xFFFFD93D),
    'Vegetables': Color(0xFF6BCB77),
    'Dairy': Color(0xFF4D96FF),
    'Others': Color(0xFF9B59B6),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.65;
    final strokeWidth = radius - innerRadius;

    double startAngle = -pi / 2; // Start from top

    // Draw each segment
    breakdown.forEach((category, calories) {
      if (calories > 0 && total > 0) {
        final sweepAngle = (calories / total) * 2 * pi;
        final color = categoryColors[category] ?? Colors.grey;

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        startAngle += sweepAngle;
      }
    });
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return breakdown != oldDelegate.breakdown || total != oldDelegate.total;
  }
}

/// Calorie Legend Widget
class CalorieLegend extends StatelessWidget {
  final Map<String, int> breakdown;

  const CalorieLegend({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0, (sum, val) => sum + val);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: breakdown.entries.map((entry) {
        final category = entry.key;
        final calories = entry.value;
        final percentage = total > 0 ? (calories / total * 100).round() : 0;
        final color = _DonutChartPainter.categoryColors[category] ?? Colors.grey;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$category $percentage%',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
