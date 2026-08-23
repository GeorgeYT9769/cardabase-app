import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/migrations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

extension GetItExtensions on GetIt {
  void registerCards() {
    registerLazySingletonAsync<LoyaltyCardsBox>(
      () async {
        // Register the new cards box synchronously and defer heavy
        // migration work to run in the background so startup isn't blocked.
        // ignore: avoid_print
        print('registerCards: starting cards registration (deferred migration)');
        final hive = await getAsync<HiveInterface>();

        // open new box (fast), return it immediately
        // ignore: avoid_print
        print('registerCards: opening new cards202603 box');
        late LoyaltyCardsBox newCardsBox;
        try {
          newCardsBox = await hive.openBox<LoyaltyCard>('cards202603');
        } catch (e, s) {
          // Do not delete here. Deleting the box can permanently remove cards.
          // Instead, surface the error so we can keep data intact and show a
          // clear startup failure message.
          // ignore: avoid_print
          print('registerCards: failed opening cards202603: $e\n$s');
          rethrow;
        }

        if (newCardsBox.isEmpty) {
          // Run migration in background so we don't block app startup.
          Future(() async {
            try {
              // ignore: avoid_print
              print('registerCards: background migration start');
              final oldCardsBox = await hive.openBox('mybox');
              await migrateCardsBoxTo202603(oldCardsBox, newCardsBox);
              await oldCardsBox.close();

              await _fixDuplicationBugData(newCardsBox);
              await _fixUsePointsData(newCardsBox);
              // ignore: avoid_print
              print('registerCards: background migration finished');
            } catch (e, s) {
              // ignore: avoid_print
              print('registerCards: background migration failed: $e\n$s');
            }
          });
        } else {
          // Even if not empty, we might need to fix data for users who
          // already have the new box but are upgrading to a version with
          // usePoints or other data fixes.
          Future(() async {
            await _fixDuplicationBugData(newCardsBox);
            await _fixUsePointsData(newCardsBox);
          });
        }

        return newCardsBox;
      },
      dispose: (box) => box.close(),
    );
  }
}

Future<void> _fixUsePointsData(LoyaltyCardsBox box) async {
  try {
    final Map<String, LoyaltyCard> updates = {};
    for (final card in box.values) {
      // If a card has points but usePoints is false, it's likely an old card
      // that was created before the usePoints toggle was added.
      if (card.points != 0 && !card.usePoints) {
        final updatedCard = card.copyWith(usePoints: true);
        updates[updatedCard.id] = updatedCard;
      }
    }

    if (updates.isNotEmpty) {
      await box.putAll(updates);
    }
  } catch (e, s) {
    // ignore: avoid_print
    print('Failed to fix usePoints data: $e\n$s');
  }
}

Future<void> _fixDuplicationBugData(Box<LoyaltyCard> newCardsBox) async {
  // TODO remove this method. It is only to fix the data created in the duplication bug
  try {
    // We iterate backwards to safely delete by index without shifting the
    // remaining indices. If an entry's key at the index does not equal the
    // card.id stored in that position, it was likely added without using
    // the card.id as the key and should be removed.
    for (var i = newCardsBox.length - 1; i >= 0; i--) {
      final dynamic key = newCardsBox.keyAt(i);
      final card = newCardsBox.getAt(i);
      if (card == null) continue;
      if (key != card.id) {
        await newCardsBox.deleteAt(i);
      }
    }
  } catch (e, s) {
    // ignore: avoid_print
    print('Failed to fix duplication bug data: $e\n$s');
  }
}
