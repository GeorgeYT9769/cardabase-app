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

        return newCardsBox;
      },
      dispose: (box) => box.close(),
    );
  }
}
