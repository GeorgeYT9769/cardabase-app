import 'package:cardabase/feature/errors/widgets/application_error_dialog.dart';
import 'package:flutter/material.dart';

class FlutterErrorHandler {
  const FlutterErrorHandler({
    required this.navigatorKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  void handleError(FlutterErrorDetails error) {
    FlutterError.presentError(error);
    final context = navigatorKey.currentContext;
    if (navigatorKey.currentState == null ||
        context == null ||
        !context.mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null || context.mounted) {
        return;
      }

      bool isDialogOpen = false;
      navigatorKey.currentState!.popUntil((route) {
        if (route is PopupRoute && route.isActive) {
          isDialogOpen = true;
          return false;
        }
        return true;
      });

      if (isDialogOpen) {
        return;
      }

      showApplicationErrorDialog(context, error);
    });
  }
}
