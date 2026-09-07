import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/migrations.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/main.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:cardabase/pages/lock_screen.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';

import '../test_helpers/fakers/loyalty_card.dart';
import '../test_helpers/fakers/settings.dart';
import 'app_harness.dart';

void main() => testMain();

void testMain() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final validEan13 = faker.loyaltyCards.codeEAN13();

  useApp();

  group('starting the app', () {
    testWidgets('opens on the cards of the user', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'shop-1',
        faker.loyaltyCards.simpleCard().copyWith(id: 'shop-1', name: 'Shop 1'),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      expect(find.text('Shop 1'), findsOneWidget);
    });

    testWidgets('shows what is new after an update', (tester) async {
      // ARRANGE the welcome screen is what the app opens on when the version
      // which was last seen is not the one which is running.
      usePhoneView(tester);
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      await settingsBox.save(faker.settings.settings(lastSeenAppVersion: null));

      // ACT
      await tester.pumpWidget(
        Main(initialScreen: WelcomeScreen(currentAppVersion: testAppVersion)),
      );
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.textContaining('Welcome'), findsWidgets);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Cardabase'), findsOneWidget);
      expect(
        settingsBox.value.lastSeenAppVersion,
        testAppVersion,
        reason: 'the welcome screen should not come back on the next start',
      );
    });

    testWidgets('asks for the password when the app is locked', (tester) async {
      // ARRANGE a user who put a password in front of the app.
      usePhoneView(tester);
      final passwordBox =
          await GetIt.I.getAsync<Box>(instanceName: 'passwordBox');
      await passwordBox.putAll({'PW': 'letmein', 'lock_app': true});
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'shop-1',
        faker.loyaltyCards.simpleCard().copyWith(id: 'shop-1', name: 'Shop 1'),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: LockScreen()));
      await tester.pumpAndSettle();

      // ASSERT the cards stay behind the lock screen until the password is in.
      expect(find.byType(Homepage), findsNothing);
      expect(find.text('Shop 1'), findsNothing);
      expect(find.text('Enter your password to continue'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'letmein');
      await tester.pumpAndSettle();
      await tester.tap(find.text('UNLOCK'));
      await tester.pumpAndSettle();

      expect(find.byType(Homepage), findsOneWidget);
      expect(find.text('Shop 1'), findsOneWidget);
    });

    testWidgets('a card which was added is still there after a restart',
        (tester) async {
      // ARRANGE
      usePhoneView(tester);
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await tester.tap(find.byIcon(Icons.add_card));
      await tester.pumpAndSettle();
      await tester.enterText(fieldWithLabel('Card Name'), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Card Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'EAN-13'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldWithLabel('Card ID'), validEan13);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();
      expect(find.text('Delhaize'), findsOneWidget);

      // the app is built again over the same database, the way a user comes
      // back to it the next day.
      await restart(tester, Homepage());

      // ASSERT
      expect(find.text('Delhaize'), findsOneWidget);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(
        loyaltyCardsBox.values.map((card) => card.name),
        ['Delhaize'],
      );
    });

    testWidgets('a theme which was chosen is still there after a restart',
        (tester) async {
      // ARRANGE
      usePhoneView(tester);
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();

      await restart(tester, Homepage());

      // ASSERT
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      expect(settingsBox.value.theme.useDarkMode, isTrue);
      expect(
        Theme.of(tester.element(find.text('Cardabase'))).brightness,
        Brightness.dark,
      );
    });

    testWidgets('the view options are still there after a restart',
        (tester) async {
      // ARRANGE two cards which sort differently by name than by age, so the
      // order on screen says which of the two is being used.
      usePhoneView(tester);
      final delhaize = faker.loyaltyCards.simpleCard().copyWith(
            id: 'delhaize',
            name: 'Delhaize',
            lastModifiedAt: DateTime.utc(2024, 1, 1, 12, 1),
          );
      final colruyt = faker.loyaltyCards.simpleCard().copyWith(
            id: 'colruyt',
            name: 'Colruyt',
            lastModifiedAt: DateTime.utc(2024, 1, 1, 12),
          );
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox
          .putAll({delhaize.id: delhaize, colruyt.id: colruyt});
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      await settingsBox.save(
        faker.settings.settings(
          cardListViewOptions: faker.settings
              .cardListViewOptions(sortingStyle: SortingStyle.latest),
        ),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      expect(shownCardIds(tester), [delhaize.id, colruyt.id]);

      // ACT the sort button lives in the search row, which the search icon
      // in the app bar opens.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenu<SortingStyle>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name 0-Z').last);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Slider), const Offset(200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SELECT'));
      await tester.pumpAndSettle();
      final chosenColumns =
          settingsBox.value.cardListViewOptions.numberOfColumns;
      expect(chosenColumns, greaterThan(1));

      await restart(tester, Homepage());

      // ASSERT the cards come back in the order which was chosen,
      expect(
        settingsBox.value.cardListViewOptions.sortingStyle,
        SortingStyle.nameAz,
      );
      expect(shownCardIds(tester), [colruyt.id, delhaize.id]);

      // and the dialog opens on the number of columns which was chosen.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      expect(find.text('Columns: $chosenColumns'), findsOneWidget);
    });
  });

  group('a database of an older version', () {
    /// The box the older versions of the app stored their cards in. It is not
    /// one of the boxes the harness clears, so every test which writes it puts
    /// it back the way it found it.
    Future<Box> openLegacyBox() async {
      final hive = await GetIt.I.getAsync<HiveInterface>();
      addTearDown(() async {
        final box = await hive.openBox('mybox');
        await box.clear();
        await box.close();
      });
      return hive.openBox('mybox');
    }

    testWidgets('is carried over when the app starts', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final oldBox = await openLegacyBox();
      await oldBox.put('CARDLIST', [
        faker.loyaltyCards.legacyDbModel(name: 'Delhaize', uniqueId: '1'),
        faker.loyaltyCards.legacyDbModel(name: 'Colruyt', uniqueId: '2'),
      ]);

      // ACT the migration is what the app runs before it builds anything.
      await runLoyaltyCardMigrations();
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ASSERT the cards are in the new box and on the screen.
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(
        loyaltyCardsBox.values.map((card) => card.name),
        containsAll(['Delhaize', 'Colruyt']),
      );
      expect(find.text('Delhaize'), findsOneWidget);
    });

    testWidgets('keeps what a card of an older version held', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final oldBox = await openLegacyBox();
      final legacyEan13 = faker.loyaltyCards.codeEAN13();
      await oldBox.put('CARDLIST', [
        faker.loyaltyCards.legacyDbModel(
          name: 'Delhaize',
          data: legacyEan13,
          uniqueId: 'delhaize',
          note: 'The one on the corner',
          points: 12,
        ),
      ]);

      // ACT
      await runLoyaltyCardMigrations();
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delhaize'));
      await tester.pumpAndSettle();

      // ASSERT the card opens with everything the old one had.
      expect(find.text('The one on the corner'), findsOneWidget);
      expect(find.text('12 points'), findsOneWidget);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(loyaltyCardsBox.get('delhaize')?.barcode.data, legacyEan13);
    });

    testWidgets('is not carried over a second time', (tester) async {
      // ARRANGE a user who already started the new version once.
      usePhoneView(tester);
      final oldBox = await openLegacyBox();
      await oldBox.put('CARDLIST', [
        faker.loyaltyCards.legacyDbModel(name: 'Delhaize', uniqueId: '1'),
      ]);
      await runLoyaltyCardMigrations();
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(loyaltyCardsBox.values, hasLength(1));

      // ACT the app starts again over the same two databases.
      await runLoyaltyCardMigrations();
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ASSERT the card is not there twice.
      expect(loyaltyCardsBox.values, hasLength(1));
      expect(find.text('Delhaize'), findsOneWidget);
    });
  });
}
