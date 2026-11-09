import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Conector curvo em S (Curva Bézier) ligando dois nós consecutivos em uma trilha senoidal.
class TrailConnectorSegment extends StatelessWidget {
  final double fromOffsetX;
  final double toOffsetX;
  final bool isCompleted;
  final double height;

  const TrailConnectorSegment({
    super.key,
    required this.fromOffsetX,
    required this.toOffsetX,
    this.isCompleted = false,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _TrailCurvePainter(
          fromOffsetX: fromOffsetX,
          toOffsetX: toOffsetX,
          color: isCompleted ? AppColors.chessGreen : AppColors.surfaceElevated,
        ),
      ),
    );
  }
}

class _TrailCurvePainter extends CustomPainter {
  final double fromOffsetX;
  final double toOffsetX;
  final Color color;

  _TrailCurvePainter({
    required this.fromOffsetX,
    required this.toOffsetX,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final startX = centerX + fromOffsetX;
    final endX = centerX + toOffsetX;

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(
        startX,
        size.height * 0.55,
        endX,
        size.height * 0.45,
        endX,
        size.height,
      );

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, bgPaint);
    canvas.drawPath(path, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _TrailCurvePainter oldDelegate) {
    return oldDelegate.fromOffsetX != fromOffsetX ||
        oldDelegate.toOffsetX != toOffsetX ||
        oldDelegate.color != color;
  }
}
