import 'package:flutter/material.dart';

class CustomSnackBarContent extends StatelessWidget {
  final String message;
  final bool success;

  const CustomSnackBarContent({
    super.key,
    required this.message,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          success ? Icons.check : Icons.error,
          size: 20,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

SnackBar buildCustomSnackBar(String message, bool success) {
  return SnackBar(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    content: CustomSnackBarContent(message: message, success: success),
    duration: const Duration(milliseconds: 3000),
    padding: const EdgeInsets.all(5.0),
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.vertical,
    backgroundColor: success
        ? const Color.fromARGB(255, 92, 184, 92)
        : const Color.fromARGB(255, 237, 67, 55),
  );
}
