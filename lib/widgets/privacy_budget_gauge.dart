import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';

class PrivacyBudgetGauge extends StatelessWidget {
  final double currentEpsilon;
  final double maxEpsilon;

  const PrivacyBudgetGauge({
    super.key,
    required this.currentEpsilon,
    this.maxEpsilon = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentEpsilon / maxEpsilon).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _GaugePainter(progress: progress),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentEpsilon.toStringAsFixed(1)} / ${maxEpsilon.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Epsilon (ε) Spent',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;

  _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Track Paint
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5,
      false,
      trackPaint,
    );

    // Progress Gradient Paint
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.secondaryCyan, AppTheme.primaryViolet, Colors.pinkAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
