import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/migrations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

extension GetItExtensions on GetIt {
  void registerCards() {
    registerLazySingletonAsync<LoyaltyCardsBox>(
      () async {
        final hive = await getAsync<HiveInterface>();

        final oldCardsBox = await hive.openBox('mybox');
        final newCardsBox = await Hive.openBox<LoyaltyCard>('cards202603');

        await migrateCardsBoxTo202603(oldCardsBox, newCardsBox);
        await oldCardsBox.close();

        await _fixDuplicationBugData(newCardsBox);

        return newCardsBox;
      },
      dispose: (box) => box.close(),
    );
  }
}

Future<void> _fixDuplicationBugData(Box<LoyaltyCard> newCardsBox) async {
  // TODO remove this method. It is only to fix the data created in the duplication bug
  final ids = newCardsBox.values.map((card) => card.id).toList(growable: false);
  for (final id in ids) {
    if (newCardsBox.containsKey(id)) {
      continue;
    }

    // if the card id does not exist in the cards-box as a key, it was "added",
    // not "put", and we should remove it.
    for (var i = 0; i < newCardsBox.length; i++) {
      if (newCardsBox.getAt(i)?.id == id) {
        await newCardsBox.deleteAt(i);
      }
    }
  }
}
