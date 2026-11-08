import 'package:flutter/material.dart';

class PawnLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool hasBadge;

  const PawnLogo({
    super.key,
    this.size = 28,
    this.color,
    this.hasBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    if (!hasBadge) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: PawnLogoPainter(color: effectiveColor),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            effectiveColor.withOpacity(0.22),
            effectiveColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: effectiveColor.withOpacity(0.4),
          width: size * 0.04,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withOpacity(0.25),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: CustomPaint(
        painter: PawnLogoPainter(color: effectiveColor),
      ),
    );
  }
}

class PawnLogoPainter extends CustomPainter {
  final Color color;

  PawnLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Cabeça esférica do peão
    final headRadius = w * 0.24;
    final headCenter = Offset(w * 0.5, h * 0.24);
    canvas.drawCircle(headCenter, headRadius, paint);

    // 2. Colar / Anel superior
    final collarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.46),
        width: w * 0.44,
        height: h * 0.08,
      ),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(collarRect, paint);

    // 3. Tronco esbelto curvado
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.36, h * 0.48);
    bodyPath.cubicTo(
      w * 0.40, h * 0.62,
      w * 0.28, h * 0.74,
      w * 0.22, h * 0.82,
    );
    bodyPath.lineTo(w * 0.78, h * 0.82);
    bodyPath.cubicTo(
      w * 0.72, h * 0.74,
      w * 0.60, h * 0.62,
      w * 0.64, h * 0.48,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // 4. Anel da Base
    final baseTier = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.86),
        width: w * 0.72,
        height: h * 0.08,
      ),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseTier, paint);

    // 5. Pedestal inferior largo
    final pedestal = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.95),
        width: w * 0.88,
        height: h * 0.09,
      ),
      Radius.circular(h * 0.045),
    );
    canvas.drawRRect(pedestal, paint);
  }

  @override
  bool shouldRepaint(covariant PawnLogoPainter oldDelegate) =>
      color != oldDelegate.color;
}
