import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/widgets/custom_snack_bar.dart';
import 'package:cardabase/util/vibration_provider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
Future<bool> showImportCardsDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const ImportDialog(),
  ).then((result) => result == true);
}

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final textController = TextEditingController();

  Future<void> onImportClicked() async {
    final input = textController.text.trim();
    if (input.isEmpty) {
      GetIt.I<VibrationProvider>().vibrateSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('No data!', false),
      );
      return;
    }

    int count = 0;
    final cards = input
        .split('\n')
        .map((line) => LoyaltyCard.fromLegacyExport(line, (count++).toString()))
        .toList(growable: false);

    if (cards.isNotEmpty) {
      await cardsBox.clear();
      await cardsBox.addAll(cards);
    }
    textController.text = '';

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      buildCustomSnackBar('Imported $count cards!', true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Import Card Data',
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.inverseSurface, fontSize: 30),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _inputField(theme),
      ),
      actions: [
        _cancelButton(theme),
        _importButton(theme),
      ],
    );
  }

  Widget _inputField(ThemeData theme) {
    return TextField(
      controller: textController,
      maxLines: 10,
      decoration: InputDecoration(
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 15,
        ),
        hintText:
            'This action will rewrite existing cards!\n \nPaste your Cardabase here:',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(width: 2.0),
        ),
        focusColor: theme.colorScheme.primary,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.tertiary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _cancelButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        side: BorderSide(color: theme.colorScheme.primary, width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Text(
        'Cancel',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }

  Widget _importButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: onImportClicked,
      style: OutlinedButton.styleFrom(
        elevation: 0.0,
        side: BorderSide(color: theme.colorScheme.primary, width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Text(
        'Import',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}
