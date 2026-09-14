import 'package:flutter/material.dart';

class StartupError extends StatelessWidget {
  const StartupError({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Cardabase failed to initialize local data.\n\nError:\n$error\n\nPlease restart the app. If this keeps happening, export your data from the old version and reinstall.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
