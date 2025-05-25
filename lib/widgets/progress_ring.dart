import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final bool isWater;
  final bool isCalories; // New parameter for calories
  final Color color;

  const ProgressRing({
    required this.value,
    required this.maxValue,
    required this.label,
    this.isWater = false,
    this.isCalories = false, // Default to false
    this.color = const Color(0xFF8B4513),
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    String displayValue;
    String displayMax;

    if (isWater) {
      displayValue =
          (value * 4.22675).round().toString(); // Convert liters to cups
      displayMax = (maxValue * 4.22675).round().toString();
    } else if (isCalories) {
      displayValue = value.toInt().toString();
      displayMax = maxValue.toInt().toString();
    } else {
      displayValue = value.toInt().toString();
      displayMax = maxValue.toInt().toString();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _ProgressRingPainter(percentage, color),
            child: Center(
              child: Text(
                '$displayValue\nof $displayMax',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) {
      return Colors.green;
    } else if (percentage >= 0.75) {
      return Colors.lightGreen;
    } else if (percentage >= 0.50) {
      return Colors.yellow;
    } else if (percentage >= 0.25) {
      return Colors.orange;
    } else {
      return this.color; // Default color for less than 25%
    }
  }

  _ProgressRingPainter(this.percentage, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background circle
    final backgroundPaint =
        Paint()
          ..color = Colors.grey[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress circle
    final progressPaint =
        Paint()
          ..color = _getProgressColor(percentage)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final progressAngle = 2 * 3.14159 * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
