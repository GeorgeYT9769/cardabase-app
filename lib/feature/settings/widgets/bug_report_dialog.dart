import 'dart:io';

import 'package:cardabase/config/secrets.dart';
import 'package:cardabase/util/form_validation.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';

class BugReportDialog extends StatefulWidget {
  const BugReportDialog({super.key});

  @override
  State<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<BugReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bug = TextEditingController();

  bool isSending = false;

  Future<void> send() async {
    final text = _bug.text.trim();
    if (text.isEmpty) {
      return;
    }
    try {
      setState(() => isSending = true);

      final sent = await _sendToDiscordWebhook(text);
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          sent ? 'Bug report sent!' : 'Bug report failed!',
          sent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  Future<bool> _sendToDiscordWebhook(String message) async {
    try {
      final uri = Uri.parse(discordWebhookUrl);
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      final body = '{"content": "**Bug Report:**\\n$message"}';
      request.write(body);
      final response = await request.close();
      httpClient.close();
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error sending bug report: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Report a Bug',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describe the issue you encountered:',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 12),
            _bugFormField(theme),
          ],
        ),
      ),
      actions: [
        Center(
          child: _sendButton(theme),
        ),
      ],
    );
  }

  Widget _bugFormField(ThemeData theme) {
    return TextFormField(
      controller: _bug,
      maxLines: 5,
      minLines: 3,
      validator: isNotEmpty(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(width: 2.0),
        ),
        focusColor: theme.colorScheme.primary,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.secondary,
        ),
        prefixIcon: Icon(
          Icons.bug_report,
          color: theme.colorScheme.secondary,
        ),
        labelText: 'Bug description',
        alignLabelWithHint: true,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _sendButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: isSending ? null : send,
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: isSending
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.tertiary,
              ),
            )
          : Text(
              'SEND',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.inverseSurface,
              ),
            ),
    );
  }
}
