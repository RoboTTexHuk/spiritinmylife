import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoderSpiralSpirit extends StatefulWidget {
  const LoderSpiralSpirit({Key? key}) : super(key: key);

  @override
  State<LoderSpiralSpirit> createState() => _LoderSpiralSpiritState();
}

class _LoderSpiralSpiritState extends State<LoderSpiralSpirit>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _t;

  // Настройки анимации
  final double _durationSec = 2.2; // один цикл
  final int _turns = 3; // оборотов за цикл
  final double _startRadius = 120;
  final double _endRadius = 6;
  final double _startFont = 46;
  final double _endFont = 12;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_durationSec * 1000).round()),
    )..repeat();
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cx = constraints.maxWidth / 2;
          final cy = constraints.maxHeight / 2;

          return AnimatedBuilder(
            animation: _t,
            builder: (context, child) {
              final t = _t.value; // 0..1
              final radius = _startRadius + (_endRadius - _startRadius) * t;
              final angle = 2 * math.pi * (_turns * t);
              final x = cx + radius * math.cos(angle);
              final y = cy + radius * math.sin(angle);
              final fontSize = _startFont + (_endFont - _startFont) * t;
              final opacity = 0.95 - 0.6 * t;
              final selfRotate = angle + 0.5 * math.pi;

              return Stack(
                children: [
                  Positioned(
                    left: x,
                    top: y,
                    child: Transform.translate(
                      offset: const Offset(-10, -10),
                      child: Transform.rotate(
                        angle: selfRotate,
                        child: Opacity(
                          opacity: opacity.clamp(0.2, 1.0),
                          child: Text(
                            'Spirit',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CenterGlowPainter(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CenterGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.25;
    final gradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.07),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}