import 'dart:ui';
import 'package:flutter/material.dart';

class BlurAppBarBackground extends StatelessWidget {

  const BlurAppBarBackground({super.key, this.alpha = 0});

  final double alpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: theme.colorScheme.surface.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
