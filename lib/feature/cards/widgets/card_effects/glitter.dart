import 'package:flutter/material.dart';

class GlitterOverlay extends StatefulWidget {
  const GlitterOverlay({super.key});

  @override
  State<GlitterOverlay> createState() => _GlitterOverlayState();
}

class _GlitterOverlayState extends State<GlitterOverlay> {
  final int _starCount = 5; // Fewer stars for performance

  late List<_GlitterStar> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(_starCount, (i) => _GlitterStar.random());
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlitterPainter(_stars),
      size: Size.infinite,
    );
  }
}

class _GlitterStar {
  static final List<String> symbols = [
    '*',
    '✦',
    '✬',
    '✯',
    '˚',
    '｡',
    '❀',
    '+',
    '-',
    '/',
    '♪',
    '♫',
  ];

  _GlitterStar(this.x, this.y, this.size, this.color, this.symbol);

  final double x;
  final double y;
  final double size;
  final Color color;
  final String symbol;

  static _GlitterStar random() {
    final rnd = UniqueKey().hashCode;
    final x = (rnd % 1000) / 1000.0;
    final y = ((rnd ~/ 1000) % 1000) / 1000.0;
    final size = 18.0 + (rnd % 8); // Large for visibility
    final color = Colors.white.withValues(alpha: 0.5); // More transparent
    final symbol = symbols[rnd % symbols.length];
    return _GlitterStar(x, y, size, color, symbol);
  }
}

class _GlitterPainter extends CustomPainter {
  _GlitterPainter(this.stars);

  final List<_GlitterStar> stars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final px = star.x * size.width;
      final py = star.y * size.height;
      final textPainter = TextPainter(
        text: TextSpan(
          text: star.symbol,
          style: TextStyle(
            fontSize: star.size,
            color: star.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(px - textPainter.width / 2, py - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter oldDelegate) => false;
}
