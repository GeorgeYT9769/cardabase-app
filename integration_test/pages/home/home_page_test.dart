import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/main.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import '../../../test_helpers/fakers/loyalty_card.dart';
import '../../../test_helpers/fakers/settings.dart';
import '../../app_harness.dart';

void main() => testHomePage();

void testHomePage() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  useApp();

  group('the card list', () {
    testWidgets('says there is nothing to see when there are no cards',
        (tester) async {
      // ARRANGE
      usePhoneView(tester);

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('There is nothing to see...'), findsOneWidget);
    });

    testWidgets('shows the cards which are stored', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({
        'delhaize': faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
        'colruyt': faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'colruyt', name: 'Colruyt'),
      });

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Delhaize'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Colruyt'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Colruyt'), findsOneWidget);
      expect(find.text('There is nothing to see...'), findsNothing);
    });
  });

  group('the search', () {
    /// Puts two cards on the home page and opens the search bar over them.
    Future<void> openSearchOverTwoCards(WidgetTester tester) async {
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({
        'delhaize': faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
        'colruyt': faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'colruyt', name: 'Colruyt'),
      });
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
    }

    testWidgets('keeps only the cards whose name matches', (tester) async {
      // ARRANGE
      await openSearchOverTwoCards(tester);

      // ACT
      await tester.enterText(find.byType(TextFormField), 'col');
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Colruyt'), findsOneWidget);
      expect(find.text('Delhaize'), findsNothing);
    });

    testWidgets('ignores the case of what is typed', (tester) async {
      // ARRANGE
      await openSearchOverTwoCards(tester);

      // ACT
      await tester.enterText(find.byType(TextFormField), 'COLRUYT');
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Colruyt'), findsOneWidget);
      expect(find.text('Delhaize'), findsNothing);
    });

    testWidgets('says so when no card matches', (tester) async {
      // ARRANGE
      await openSearchOverTwoCards(tester);

      // ACT
      await tester.enterText(find.byType(TextFormField), 'albert heijn');
      await tester.pumpAndSettle();

      // ASSERT the empty list of a search reads differently from the empty
      // list of a user who has no cards at all.
      expect(find.text('No cards match your search...'), findsOneWidget);
      expect(find.text('There is nothing to see...'), findsNothing);
    });

    testWidgets('brings the other cards back when the field is cleared',
        (tester) async {
      // ARRANGE
      await openSearchOverTwoCards(tester);
      await tester.enterText(find.byType(TextFormField), 'col');
      await tester.pumpAndSettle();
      expect(find.text('Delhaize'), findsNothing);

      // ACT
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Delhaize'), findsOneWidget);
    });

    testWidgets('forgets what was typed when the search is closed',
        (tester) async {
      // ARRANGE
      await openSearchOverTwoCards(tester);
      await tester.enterText(find.byType(TextFormField), 'col');
      await tester.pumpAndSettle();

      // ACT the search icon turns into the one which closes the bar again.
      await tester.tap(find.byIcon(Icons.search_off));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Delhaize'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
        reason: 'the field should not still hold the previous search',
      );
    });
  });

  group('adding a card', () {
    testWidgets('a new card is shown and kept', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      final barcode = faker.loyaltyCards.codeEAN13();
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();

      // ACT
      await tester.tap(find.byIcon(Icons.add_card));
      await tester.pumpAndSettle();
      await tester.enterText(fieldWithLabel('Card Name'), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Card Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'EAN-13'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldWithLabel('Card ID'), barcode);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Cardabase'), findsOneWidget, reason: 'back on home');
      expect(find.text('Delhaize'), findsOneWidget);
      expect(loyaltyCardsBox.values.map((card) => card.name), ['Delhaize']);
      expect(loyaltyCardsBox.values.single.barcode.data, barcode);
    });

    testWidgets('a card without a name is not saved', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();

      // ACT
      await tester.tap(find.byIcon(Icons.add_card));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(loyaltyCardsBox.values, isEmpty);
    });
  });

  group('the menu of a card', () {
    testWidgets('duplicates a card, copy and all', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await openCardMenu(tester, 'Delhaize');
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      // ASSERT
      final cards = loyaltyCardsBox.values.toList(growable: false);
      expect(cards.map((card) => card.name), ['Delhaize', 'Delhaize']);
      expect(
        cards.first.barcode.data,
        cards.last.barcode.data,
        reason: 'a duplicate holds the same card',
      );
      expect(
        cards.first.id,
        isNot(cards.last.id),
        reason: 'but it is a card of its own',
      );
    });

    testWidgets('moves a card down the order of the user', (tester) async {
      // ARRANGE moving cards around is only offered while the user sorts them
      // themselves, and it is that order which is changed.
      usePhoneView(tester);
      final first = faker.loyaltyCards
          .simpleCard()
          .copyWith(id: 'delhaize', name: 'Delhaize');
      final second = faker.loyaltyCards
          .simpleCard()
          .copyWith(id: 'colruyt', name: 'Colruyt');
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({first.id: first, second.id: second});
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      await settingsBox.save(
        faker.settings.settings(
          cardListViewOptions: faker.settings.cardListViewOptions(
            sortingStyle: SortingStyle.custom,
            customOrder: [first.id, second.id],
          ),
        ),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await openCardMenu(tester, 'Delhaize');
      await tester.tap(find.text('Move DOWN'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(
        settingsBox.value.cardListViewOptions.customOrder,
        [second.id, first.id],
      );
    });

    testWidgets('moves a card up the order of the user', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final first = faker.loyaltyCards
          .simpleCard()
          .copyWith(id: 'delhaize', name: 'Delhaize');
      final second = faker.loyaltyCards
          .simpleCard()
          .copyWith(id: 'colruyt', name: 'Colruyt');
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({first.id: first, second.id: second});
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      await settingsBox.save(
        faker.settings.settings(
          cardListViewOptions: faker.settings.cardListViewOptions(
            sortingStyle: SortingStyle.custom,
            customOrder: [first.id, second.id],
          ),
        ),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await tester.scrollUntilVisible(find.text('Colruyt'), 200);
      await tester.pumpAndSettle();
      await openCardMenu(tester, 'Colruyt');
      await tester.tap(find.text('Move UP'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(
        settingsBox.value.cardListViewOptions.customOrder,
        [second.id, first.id],
      );
    });

    testWidgets('deletes a card, after asking', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.putAll({
        'delhaize': faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
        'colruyt': faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'colruyt', name: 'Colruyt'),
      });
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await openCardMenu(tester, 'Delhaize');
      await tester.tap(find.widgetWithText(ListTile, 'DELETE'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Delete Card'), findsOneWidget);
      expect(find.textContaining('Delhaize'), findsWidgets);
      await tester.tap(find.widgetWithText(OutlinedButton, 'DELETE'));
      await tester.pumpAndSettle();

      expect(find.text('Delhaize'), findsNothing);
      expect(loyaltyCardsBox.values.map((card) => card.name), ['Colruyt']);
    });

    testWidgets('opens the card in the edit form', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await openCardMenu(tester, 'Delhaize');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(fieldText(tester, 'Card Name'), 'Delhaize');
    });
  });

  group('the view options', () {
    testWidgets('sort the cards by name', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final delhaize = faker.loyaltyCards.simpleCard().copyWith(
            id: 'delhaize',
            name: 'Delhaize',
            lastModifiedAt: DateTime.utc(2024, 1, 1, 12),
          );
      final colruyt = faker.loyaltyCards.simpleCard().copyWith(
            id: 'colruyt',
            name: 'Colruyt',
            lastModifiedAt: DateTime.utc(2024, 1, 1, 12, 1),
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
      expect(
        shownCardIds(tester),
        [colruyt.id, delhaize.id],
        reason: 'the card which changed last comes first',
      );

      // ACT
      // the sort button lives in the search row, which the search icon
      // in the app bar opens.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      // the sorting style is a slider over the styles, and A-Z is the first
      // of them, so it sits at the far left.
      await tester.drag(find.byType(Slider).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('A-Z'), findsOneWidget);
      await tester.tap(find.text('SELECT'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(
        settingsBox.value.cardListViewOptions.sortingStyle,
        SortingStyle.nameAz,
        reason: 'the choice should be saved',
      );
      expect(shownCardIds(tester), [colruyt.id, delhaize.id]);
    });

    testWidgets('remember how many columns the cards are shown in',
        (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      // the sort button lives in the search row, which the search icon
      // in the app bar opens.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      expect(find.text('Columns: 1'), findsOneWidget);
      await tester.drag(find.byType(Slider).last, const Offset(200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SELECT'));
      await tester.pumpAndSettle();

      // ASSERT
      final settingsBox = await GetIt.I.getAsync<SettingsBox>();
      expect(
        settingsBox.value.cardListViewOptions.numberOfColumns,
        greaterThan(1),
        reason: 'the choice should be saved',
      );
    });
  });
}
