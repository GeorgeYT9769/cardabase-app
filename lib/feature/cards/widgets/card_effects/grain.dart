import 'package:flutter/material.dart';

class Grain extends StatelessWidget {
  const Grain({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/noise.png',
      fit: BoxFit.cover,
      color: Colors.white.withAlpha(20),
      colorBlendMode: BlendMode.srcOver,
    );
  }
}
