import 'dart:math';
import 'package:flutter/material.dart';

class LongPressIndicator extends StatelessWidget {
  final double progress;
  final double size;

  const LongPressIndicator({
    super.key,
    required this.progress,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _LongPressPainter(progress: progress),
        ),
      ),
    );
  }
}

class _LongPressPainter extends CustomPainter {
  final double progress;

  _LongPressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 4;

    // Arka plan dairesi
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, bgPaint);

    // İlerleme halkası
    final progressPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
    
    // Orta nokta
    final centerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, 4 * progress, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _LongPressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
