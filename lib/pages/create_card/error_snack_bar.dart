import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
  BuildContext context,
  String error,
) {
  final theme = Theme.of(context);
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Row(
        children: [
          const Icon(
            Icons.error,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Text(
            error,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 3000),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.vertical,
      backgroundColor: const Color.fromARGB(255, 237, 67, 55),
    ),
  );
}
