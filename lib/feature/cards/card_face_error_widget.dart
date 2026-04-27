import 'dart:io';

import 'package:flutter/material.dart';

class CardFaceErrorWidget extends StatelessWidget {
  const CardFaceErrorWidget({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: switch (error) {
        PathNotFoundException _ =>
          Text('Card-face image file not found. Was it removed?'),
        _ => Text('Failed to load card-face.'),
      },
    );
  }
}
