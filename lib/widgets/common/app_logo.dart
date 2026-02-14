import 'package:flutter/material.dart';

/// Custom app logo widget for AssetCapture branding.
/// Renders a stylized barcode scanner logo using CustomPainter.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppLogoPainter(),
      ),
    );
  }
}

/// Painter for the AssetCapture logo. Public so it can be used for icon generation.
class AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // --- Background rounded square ---
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bgRect, bgPaint);

    // --- Subtle inner glow ---
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bgRect, glowPaint);

    // --- Barcode bars ---
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round;

    // Barcode area dimensions
    final barcodeLeft = w * 0.22;
    final barcodeRight = w * 0.78;
    final barcodeTop = h * 0.28;
    final barcodeBottom = h * 0.62;
    final barcodeWidth = barcodeRight - barcodeLeft;

    // Bar pattern: varying widths to look like a real barcode
    final barPattern = [
      // [relativeX, relativeWidth, isThick]
      [0.0, 0.035, true],
      [0.055, 0.02, false],
      [0.095, 0.035, true],
      [0.15, 0.02, false],
      [0.19, 0.02, false],
      [0.23, 0.045, true],
      [0.30, 0.02, false],
      [0.34, 0.035, true],
      [0.40, 0.02, false],
      [0.44, 0.02, false],
      [0.485, 0.045, true],
      [0.555, 0.02, false],
      [0.595, 0.035, true],
      [0.655, 0.02, false],
      [0.695, 0.02, false],
      [0.735, 0.045, true],
      [0.805, 0.02, false],
      [0.845, 0.035, true],
      [0.905, 0.02, false],
      [0.945, 0.035, true],
    ];

    for (final bar in barPattern) {
      final x = barcodeLeft + barcodeWidth * (bar[0] as double) + barcodeWidth * (bar[1] as double) / 2;
      final barW = barcodeWidth * (bar[1] as double);
      barPaint.strokeWidth = barW;
      canvas.drawLine(
        Offset(x, barcodeTop),
        Offset(x, barcodeBottom),
        barPaint,
      );
    }

    // --- Scanner line (horizontal, glowing amber) ---
    final scanY = h * 0.45;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFBBF24).withValues(alpha: 0.9),
          const Color(0xFFF59E0B),
          const Color(0xFFFBBF24).withValues(alpha: 0.9),
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(w * 0.12, scanY - 1.5, w * 0.76, 3))
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.12, scanY),
      Offset(w * 0.88, scanY),
      scanPaint,
    );

    // Scanner line glow
    final scanGlow = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFBBF24).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(w * 0.12, scanY - w * 0.04, w * 0.76, w * 0.08))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.15, scanY - w * 0.025, w * 0.7, w * 0.05),
      scanGlow,
    );

    // --- Scanner corner brackets ---
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cornerLen = w * 0.12;
    final margin = w * 0.14;
    final cornerTop = h * 0.22;
    final cornerBottom = h * 0.68;
    final cornerLeft = margin;
    final cornerRight = w - margin;

    // Top-left corner
    canvas.drawLine(Offset(cornerLeft, cornerTop + cornerLen), Offset(cornerLeft, cornerTop), cornerPaint);
    canvas.drawLine(Offset(cornerLeft, cornerTop), Offset(cornerLeft + cornerLen, cornerTop), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(cornerRight - cornerLen, cornerTop), Offset(cornerRight, cornerTop), cornerPaint);
    canvas.drawLine(Offset(cornerRight, cornerTop), Offset(cornerRight, cornerTop + cornerLen), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(cornerLeft, cornerBottom - cornerLen), Offset(cornerLeft, cornerBottom), cornerPaint);
    canvas.drawLine(Offset(cornerLeft, cornerBottom), Offset(cornerLeft + cornerLen, cornerBottom), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(cornerRight - cornerLen, cornerBottom), Offset(cornerRight, cornerBottom), cornerPaint);
    canvas.drawLine(Offset(cornerRight, cornerBottom), Offset(cornerRight, cornerBottom - cornerLen), cornerPaint);

    // --- Small checkmark badge (bottom-right) ---
    final badgeRadius = w * 0.11;
    final badgeCenter = Offset(w * 0.82, h * 0.82);

    // Badge background
    final badgeBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: badgeCenter, radius: badgeRadius));
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBgPaint);

    // Badge border
    final badgeBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBorderPaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final checkPath = Path()
      ..moveTo(badgeCenter.dx - badgeRadius * 0.4, badgeCenter.dy)
      ..lineTo(badgeCenter.dx - badgeRadius * 0.05, badgeCenter.dy + badgeRadius * 0.35)
      ..lineTo(badgeCenter.dx + badgeRadius * 0.4, badgeCenter.dy - badgeRadius * 0.3);
    canvas.drawPath(checkPath, checkPaint);

    // --- "AC" text at bottom ---
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AC',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: w * 0.1,
          fontWeight: FontWeight.w800,
          letterSpacing: w * 0.02,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, h * 0.74),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
