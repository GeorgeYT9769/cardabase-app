import 'package:cardabase/feature/cards/export/export_cards.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> showExportCardsDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => const ExportDialog(),
  );
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();

  Future<void> exportToFile() async {
    Navigator.of(context).pop();
    try {
      await exportCardsAsFile(cardsBox.values);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Exported to Downloads', true),
      );
    } on NoPermissionToExternalStorageException catch (_) {
      GetIt.I<VibrationProvider>().vibrateError();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('No permission!', false),
      );
    }
  }

  Future<void> exportToClipboard() async {
    Navigator.of(context).pop();

    await exportCardsToClipboard(cardsBox.values);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      buildCustomSnackBar('Copied to Clipboard!', true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Export As:',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: SizedBox(
        height: 150,
        child: Column(
          children: [
            _exportAsTextButton(theme),
            const SizedBox(height: 15),
            _exportAsFileButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _exportAsTextButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: exportToClipboard,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.text_fields),
          const SizedBox(width: 10),
          Text(
            'TEXT',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportAsFileButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: exportToFile,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.file_copy),
          const SizedBox(width: 10),
          Text(
            'FILE',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
