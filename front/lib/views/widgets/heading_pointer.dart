import 'package:flutter/material.dart';

class HeadingShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withValues(alpha: 0.4),
          Colors.blueAccent.withValues(alpha: 0.0),
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.relativeLineTo(-12, -35);
    path.quadraticBezierTo(center.dx, -45, center.dx + 12, -35);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
