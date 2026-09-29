import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mesh_logo.dart';

class PhoneVisualWidget extends StatelessWidget {
  const PhoneVisualWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 128,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E0), width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: MeshLogo(size: 32),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class RadioNodeVisualWidget extends StatelessWidget {
  final bool isActive;

  const RadioNodeVisualWidget({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isActive ? AppTheme.lime : const Color(0xFFA0AEC0);
    final bgColor = isActive ? AppTheme.lime.withAlpha(30) : const Color(0xFFEDF2F7);
    final borderColor = isActive ? AppTheme.lime : const Color(0xFFCBD5E0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 84,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 3.5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.lime.withAlpha(60),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RadioTowerIcon(size: 34, color: activeColor),
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? 'ON' : 'OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadioTowerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const RadioTowerIcon({
    super.key,
    this.size = 24,
    this.color = AppTheme.lime,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadioTowerPainter(color: color),
      ),
    );
  }
}

class _RadioTowerPainter extends CustomPainter {
  final Color color;

  _RadioTowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Onda exterior izquierda
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.85, height: h * 0.85),
      2.5,
      1.2,
      false,
      paint,
    );

    // Onda exterior derecha
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.85, height: h * 0.85),
      -0.6,
      1.2,
      false,
      paint,
    );

    // Onda interior izquierda
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.48, height: h * 0.48),
      2.4,
      1.4,
      false,
      paint,
    );

    // Onda interior derecha
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.48, height: h * 0.48),
      -0.7,
      1.4,
      false,
      paint,
    );

    // Mástil central
    canvas.drawLine(Offset(w * 0.5, h * 0.45), Offset(w * 0.5, h * 0.88), paint);
    // Base de la antena
    canvas.drawLine(Offset(w * 0.38, h * 0.88), Offset(w * 0.62, h * 0.88), paint);
    // Punto emisor central
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), 2.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RadioTowerPainter oldDelegate) => oldDelegate.color != color;
}
