import 'package:flutter/material.dart';

class SnowyOverlay extends StatefulWidget {
  const SnowyOverlay({super.key});

  @override
  State<SnowyOverlay> createState() => _SnowyOverlayState();
}

class _SnowyOverlayState extends State<SnowyOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _SnowyPainter(_controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _SnowyPainter extends CustomPainter {
  final double progress;
  _SnowyPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final sparkleCount = 18;
    for (int i = 0; i < sparkleCount; i++) {
      final t = (progress + i / sparkleCount) % 1.0;
      final x = size.width * (0.1 + 0.8 * (i % 3) / 2 + 0.2 * t);
      final y = size.height * ((i / sparkleCount + t) % 1.0);
      final radius = 1.5 + 2.5 * (1 - (t - 0.5).abs() * 2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
