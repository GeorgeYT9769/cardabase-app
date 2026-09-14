import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

extension GetItExtensions on GetIt {
  void registerCards() {
    registerLazySingletonAsync<LoyaltyCardsBox>(
      () async {
        // Register the new cards box synchronously and defer heavy
        // migration work to run in the background so startup isn't blocked.
        // ignore: avoid_print
        print(
            'registerCards: starting cards registration (deferred migration)');
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

        return newCardsBox;
      },
      dispose: (box) => box.close(),
    );
  }
}
