import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MeshLogo extends StatelessWidget {
  final double size;
  final Color nodeColor;
  final Color accentColor;

  const MeshLogo({
    super.key,
    this.size = 80,
    this.nodeColor = AppTheme.lime,
    this.accentColor = AppTheme.orange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MeshLogoPainter(
          nodeColor: nodeColor,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _MeshLogoPainter extends CustomPainter {
  final Color nodeColor;
  final Color accentColor;

  _MeshLogoPainter({
    required this.nodeColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Círculo exterior sutil
    final outerRingPaint = Paint()
      ..color = nodeColor.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    canvas.drawCircle(center, radius, outerRingPaint);

    // Vértices del hexágono mesh (6 nodos perimetrales)
    final nodes = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      nodes.add(Offset(
        center.dx + radius * 0.85 * math.cos(angle),
        center.dy + radius * 0.85 * math.sin(angle),
      ));
    }

    // Líneas entre nodos perimetrales y cruzados
    final linePaint = Paint()
      ..color = nodeColor.withAlpha(200)
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    final subtleLinePaint = Paint()
      ..color = nodeColor.withAlpha(70)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;

    // Conexiones del perímetro
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(nodes[i], nodes[(i + 1) % 6], linePaint);
    }

    // Conexiones diagonales interiores y hacia el centro
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(center, nodes[i], linePaint);
      canvas.drawLine(nodes[i], nodes[(i + 2) % 6], subtleLinePaint);
    }

    // Puntos / Nodos perimetrales
    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      canvas.drawCircle(node, size.width * 0.065, nodePaint);
    }

    // Nodo Central
    canvas.drawCircle(center, size.width * 0.08, nodePaint);

    // Toque regional Maule / Antena de señal naranja inferior
    final antennaPath = Path();
    final startAntenna = Offset(center.dx - size.width * 0.07, center.dy + radius * 0.45);
    final endAntenna = Offset(center.dx, center.dy + radius * 0.82);
    antennaPath.moveTo(startAntenna.dx, startAntenna.dy);
    antennaPath.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.75,
      endAntenna.dx,
      endAntenna.dy,
    );

    final antennaPaint = Paint()
      ..color = accentColor
      ..strokeWidth = size.width * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(antennaPath, antennaPaint);
  }

  @override
  bool shouldRepaint(covariant _MeshLogoPainter oldDelegate) =>
      oldDelegate.nodeColor != nodeColor || oldDelegate.accentColor != accentColor;
}
