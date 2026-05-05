import 'dart:async';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/migrations.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive_ce.dart';

StreamSubscription? _cardsSubscription;

extension SettingsGetItExtensions on GetIt {
  void registerSettings() {
    registerLazySingletonAsync<SettingsBox>(
      () async {
        final hive = await getAsync<HiveInterface>();

        final oldSettingsBox = await hive.openBox('settingsBox');
        final newSettingsBox = await hive.openBox<Settings>('settings202603');
        final oldCardsBox = await hive.openBox('mybox');

        await migrateSettingsTo202603(
          oldSettingsBox,
          newSettingsBox,
          oldCardsBox,
        );
        await oldSettingsBox.close();
        await oldCardsBox.close();

        final cardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
        await _ensureCustomOrderContainsAllCards(cardsBox, newSettingsBox);
        _cardsSubscription = cardsBox.watch().listen(onCardsChanged);

        return newSettingsBox;
      },
      dispose: (box) {
        _cardsSubscription?.cancel();
        return box.close();
      },
    );
  }
}

extension SettingsBoxExtensions on Box<Settings> {
  Settings get value => getAt(0) ?? Settings.defaultValue();

  Future<void> save(Settings settings) {
    if (isEmpty) {
      return add(settings);
    } else {
      return putAt(0, settings);
    }
  }
}

Future<void> _ensureCustomOrderContainsAllCards(
  LoyaltyCardsBox cardsBox,
  SettingsBox settingsBox,
) async {
  final allCards = cardsBox.values.toList(growable: false);

  final settings = settingsBox.value;

  // sort cards according to the users preference before adapting it in the
  // custom order.
  settings.cardListViewOptions.sortCards(allCards);

  final idsToAdd = <String>[];
  final idsToRemove = <String>[];

  for (final card in allCards) {
    if (!settings.cardListViewOptions.customOrder.contains(card.id)) {
      idsToAdd.add(card.id);
    }
  }
  for (final cardId in settings.cardListViewOptions.customOrder) {
    if (!allCards.any((card) => card.id == cardId)) {
      idsToRemove.add(cardId);
    }
  }

  if (idsToAdd.isEmpty && idsToRemove.isEmpty) {
    return;
  }

  final editableSettings = settings.editable();
  final ids = editableSettings.cardListViewOptions.customOrder.value
      .toList(growable: true);

  for (final id in idsToRemove) {
    ids.remove(id);
  }
  ids.addAll(idsToAdd);
  editableSettings.cardListViewOptions.customOrder.value = ids;

  await settingsBox.save(editableSettings.seal());
}

Future<void> onCardsChanged(BoxEvent event) async {
  final id = event.key;
  if (id is! String) {
    print(
      'Id of card is no String. This should not happen. (Id: $id)',
    );
    return;
  }

  final settingsBox = GetIt.I<SettingsBox>();
  final settings = settingsBox.value;
  if (settings.cardListViewOptions.customOrder.contains(id)) {
    return;
  }

  final editableSettings = settings.editable();
  editableSettings.cardListViewOptions.customOrder.add(id);
  await settingsBox.save(editableSettings.seal());
}
