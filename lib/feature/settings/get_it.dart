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
        // Debug logging for settings registration. We return the new settings
        // box immediately and defer heavy migration work to the background so
        // the app can start and show UI faster.
        // ignore: avoid_print
        print('registerSettings: starting settings registration (deferred migration)');
        final hive = await getAsync<HiveInterface>();

        // open the new settings box and return it immediately
        // ignore: avoid_print
        print('registerSettings: opening new settings202603 box');
        late SettingsBox newSettingsBox;
        try {
          newSettingsBox = await hive.openBox<Settings>('settings202603');
        } catch (e, s) {
          // Do not delete here. Deleting can silently drop settings.
          // Surface the error so startup fallback can report it.
          // ignore: avoid_print
          print('registerSettings: failed opening settings202603: $e\n$s');
          rethrow;
        }

        if (newSettingsBox.isEmpty) {
          // Run migration in the background
          Future(() async {
            try {
              // ignore: avoid_print
              print('registerSettings: background migration start');
              final oldSettingsBox = await hive.openBox('settingsBox');
              final oldCardsBox = await hive.openBox('mybox');

              await migrateSettingsTo202603(
                oldSettingsBox,
                newSettingsBox,
                oldCardsBox,
              );

              await oldSettingsBox.close();
              await oldCardsBox.close();

              // When the cards box becomes available, ensure custom order and
              // start listening for card changes.
              try {
                final cardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
                await _ensureCustomOrderContainsAllCards(cardsBox, newSettingsBox);
                _cardsSubscription = cardsBox.watch().listen(onCardsChanged);
              } catch (e, s) {
                // ignore: avoid_print
                print('registerSettings: failed to ensure custom order: $e\n$s');
              }

              // ignore: avoid_print
              print('registerSettings: background migration finished');
            } catch (e, s) {
              // ignore: avoid_print
              print('registerSettings: background migration failed: $e\n$s');
            }
          });
        }

        // ignore: avoid_print
        print('registerSettings: returning settings box');
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
  Settings get value {
    // Hive getAt(0) can throw when the box is empty/corrupted; always fall
    // back to default settings to avoid startup crashes.
    if (isEmpty) {
      return Settings.defaultValue();
    }
    try {
      return getAt(0) ?? Settings.defaultValue();
    } catch (_) {
      return Settings.defaultValue();
    }
  }

  Future<void> save(Settings settings) {
    if (isEmpty) {
      return add(settings);
    }

    // If putAt fails due to a stale index state, fall back to add.
    return putAt(0, settings).catchError((_) => add(settings));
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
    return;
  }

  final settingsBox = GetIt.I<SettingsBox>();
  if (event.deleted) {
    final settings = settingsBox.value;
    if (!settings.cardListViewOptions.customOrder.contains(id)) {
      return;
    }
    final editableSettings = settings.editable();
    editableSettings.cardListViewOptions.customOrder.remove(id);
    await settingsBox.save(editableSettings.seal());
  } else {
    final settings = settingsBox.value;
    if (settings.cardListViewOptions.customOrder.contains(id)) {
      return;
    }
    final editableSettings = settings.editable();
    editableSettings.cardListViewOptions.customOrder.add(id);
    await settingsBox.save(editableSettings.seal());
  }
}
