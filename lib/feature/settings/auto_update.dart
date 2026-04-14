import 'package:cardabase/feature/cards/export/export_cards.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

Future<void> autoUpdateAfterInterval(
  BuildContext context,
  Box<Settings> settingsBox,
  LoyaltyCardsBox cardsBox,
) async {
  final settings = settingsBox.value;
  final backupSettings = settings.autoBackups;
  if (!backupSettings.isEnabled) {
    return;
  }

  final nextUpdateTimestamp =
      backupSettings.lastUpdate?.add(backupSettings.interval) ?? DateTime(0);
  if (DateTime.now().toUtc().isBefore(nextUpdateTimestamp)) {
    return;
  }

  await exportCardsAsFile(
    cardsBox.values,
    directoryPath: settings.customExportPath,
  );

  final editableSettings = settings.editable();
  editableSettings.autoBackups.lastUpdate.value = DateTime.now().toUtc();

  await settingsBox.save(editableSettings.seal());

  editableSettings.dispose();
}
