import 'dart:math' as math;

import 'package:flutter/material.dart';

class CredenceIcon extends StatelessWidget {
  const CredenceIcon({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _CredencePainter());
  }
}

class _CredencePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F1B4D), Color(0xFF1D4ED8), Color(0xFF2DD4BF)],
      ).createShader(rect);

    final outer = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.28),
    );

    canvas.drawShadow(
      Path()..addRRect(outer),
      const Color(0x33111F56),
      size.width * 0.08,
      false,
    );
    canvas.drawRRect(outer, bg);

    final innerShell = Paint()..color = Colors.white.withValues(alpha: 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.04,
          size.height * 0.04,
          size.width * 0.92,
          size.height * 0.92,
        ),
        Radius.circular(size.width * 0.24),
      ),
      innerShell,
    );

    canvas.drawCircle(
      Offset(size.width * 0.26, size.height * 0.20),
      size.width * 0.22,
      Paint()..color = const Color(0xFF67D9FF).withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.80),
      size.width * 0.17,
      Paint()..color = const Color(0xFF93F3E2).withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.78),
        width: size.width * 0.46,
        height: size.height * 0.11,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    final rearRect = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.22,
      size.width * 0.34,
      size.height * 0.46,
    );
    final rearPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF68D8FF), Color(0xFF3B82F6)],
      ).createShader(rearRect);
    final rearRRect = RRect.fromRectAndRadius(
      rearRect,
      Radius.circular(size.width * 0.08),
    );

    canvas.save();
    canvas.translate(size.width * 0.45, size.height * 0.45);
    canvas.rotate(-8 * math.pi / 180);
    canvas.translate(-size.width * 0.45, -size.height * 0.45);
    canvas.drawRRect(rearRRect, rearPaint);
    final rearFold = Path()
      ..moveTo(rearRect.right - size.width * 0.09, rearRect.top)
      ..lineTo(rearRect.right, rearRect.top)
      ..lineTo(rearRect.right, rearRect.top + size.width * 0.09)
      ..close();
    canvas.drawPath(
      rearFold,
      Paint()..color = const Color(0xFF95E4FF).withValues(alpha: 0.72),
    );
    canvas.restore();

    final frontRect = Rect.fromLTWH(
      size.width * 0.37,
      size.height * 0.27,
      size.width * 0.33,
      size.height * 0.46,
    );
    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFEEF4FF)],
      ).createShader(frontRect);
    final frontRRect = RRect.fromRectAndRadius(
      frontRect,
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(frontRRect, frontPaint);
    final frontFold = Path()
      ..moveTo(frontRect.right - size.width * 0.09, frontRect.top)
      ..lineTo(frontRect.right, frontRect.top)
      ..lineTo(frontRect.right, frontRect.top + size.width * 0.09)
      ..close();
    canvas.drawPath(frontFold, Paint()..color = const Color(0xFFD7E8FF));

    final linePaint = Paint()..color = const Color(0xFFD8E7FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.44,
          size.height * 0.40,
          size.width * 0.16,
          size.height * 0.03,
        ),
        Radius.circular(size.width * 0.015),
      ),
      linePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.44,
          size.height * 0.45,
          size.width * 0.11,
          size.height * 0.025,
        ),
        Radius.circular(size.width * 0.012),
      ),
      Paint()..color = const Color(0xFFE5EFFF),
    );

    final chipRect = Rect.fromLTWH(
      size.width * 0.43,
      size.height * 0.48,
      size.width * 0.21,
      size.height * 0.10,
    );
    final chipPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF24135F), Color(0xFF162C7A)],
      ).createShader(chipRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, Radius.circular(size.width * 0.035)),
      chipPaint,
    );
    for (final dx in [0.47, 0.515]) {
      canvas.drawCircle(
        Offset(size.width * dx, size.height * 0.53),
        size.width * 0.013,
        Paint()..color = Colors.white,
      );
    }

    final accentCenter = Offset(size.width * 0.56, size.height * 0.53);
    canvas.drawCircle(
      accentCenter,
      size.width * 0.035,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF69F0FF), Color(0xFF35D3FF)],
            ).createShader(
              Rect.fromCircle(center: accentCenter, radius: size.width * 0.035),
            ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.56, size.height * 0.523),
          width: size.width * 0.018,
          height: size.height * 0.06,
        ),
        Radius.circular(size.width * 0.009),
      ),
      Paint()..color = const Color(0xFF152A76),
    );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.542),
      size.width * 0.011,
      Paint()..color = const Color(0xFF152A76),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.44,
          size.height * 0.61,
          size.width * 0.18,
          size.height * 0.024,
        ),
        Radius.circular(size.width * 0.012),
      ),
      Paint()..color = const Color(0xFFE2EBFB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.44,
          size.height * 0.655,
          size.width * 0.14,
          size.height * 0.022,
        ),
        Radius.circular(size.width * 0.011),
      ),
      Paint()..color = const Color(0xFFEAF1FC),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
