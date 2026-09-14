import 'package:flutter/material.dart';

class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    super.key,
    required this.error,
  });

  final FlutterErrorDetails error;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Oops! Something went wrong:\n${error.exception}\nPlease send a screenshot of this error to the developer.',
      style: const TextStyle(color: Colors.red, fontSize: 18),
      textAlign: TextAlign.center,
    );
  }
}
