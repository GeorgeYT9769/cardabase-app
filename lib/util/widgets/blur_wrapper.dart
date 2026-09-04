import 'dart:ui';
import 'package:flutter/material.dart';

class BlurWrapper extends StatelessWidget {
  const BlurWrapper({
    super.key,
    required this.child,
    required this.useBlur,
    this.borderRadius,
    this.isCircle = false,
    this.blurSigma = 10.0,
  });

  final Widget child;
  final bool useBlur;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    if (!useBlur) return child;

    if (isCircle) {
      return ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: child,
      ),
    );
  }
}
