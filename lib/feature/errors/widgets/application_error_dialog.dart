import 'package:cardabase/feature/errors/widgets/error_widget.dart';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:url_launcher/url_launcher.dart';

Future<void> showApplicationErrorDialog(
  BuildContext context,
  FlutterErrorDetails error,
) {
  return showDialog(
    context: context,
    builder: (context) => ApplicationErrorDialog(error: error),
  );
}

class ApplicationErrorDialog extends StatelessWidget {
  const ApplicationErrorDialog({
    super.key,
    required this.error,
  });

  final FlutterErrorDetails error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Application Error',
        style: TextStyle(color: Colors.red),
      ),
      content: ErrorWidget(error: error),
      actions: [
        TextButton(
          onPressed: () => _launchGithubIssues(),
          child: const Text('GitHub Issue'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

Future<void> _launchGithubIssues() async {
  final githubIssuesUri =
      Uri.parse('https://github.com/GeorgeYT9769/cardabase-app/issues');
  if (!await launchUrl(githubIssuesUri)) {
    throw Exception('Could not launch $githubIssuesUri');
  }
}
