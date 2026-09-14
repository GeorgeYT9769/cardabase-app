import 'package:cardabase/feature/cards/edit/widgets/form_fields/barcode_type_selector_button.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/card_data_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/card_name_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/notes_form_field.dart';
import 'package:cardabase/feature/cards/edit/widgets/form_fields/save_button.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/add_card_button.dart';
import 'package:cardabase/main.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import '../../../test_helpers/fakers/loyalty_card.dart';
import '../../app_harness.dart';

void main() => testEditCard();

void testEditCard() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final validEan13 = faker.loyaltyCards.codeEAN13();

  useApp();

  /// Starts the app on an empty card list and opens the form of a new card.
  Future<void> openNewCardForm(WidgetTester tester) async {
    usePhoneView(tester);
    await tester.pumpWidget(Main(initialScreen: Homepage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AddCardButton));
    await tester.pumpAndSettle();
  }

  group('filling in a card', () {
    testWidgets('keeps everything which was filled in', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarcodeTypeSelectorButton));
      await tester.pumpAndSettle();
      await tester.scrollToAndTap(find.widgetWithText(ListTile, 'EAN-13'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CardDataFormField), validEan13);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(NotesFormField),
        'The one on the corner',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      final stored = loyaltyCardsBox.values.single;
      expect(stored.name, 'Delhaize');
      expect(stored.barcode.data, validEan13);
      expect(stored.barcode.type, BarcodeType.CodeEAN13);
      expect(stored.notes, 'The one on the corner');
    });

    testWidgets('starts a card without a barcode type', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(
        loyaltyCardsBox.values.single.barcode.type,
        isNull,
        reason: 'a card gets a type once the user picks one',
      );
    });

    testWidgets('shows the name on the card while it is typed', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Delhaize');
      await tester.pumpAndSettle();

      // ASSERT
      expect(
        find.text('Delhaize'),
        findsWidgets,
        reason: 'the preview should follow the name',
      );
    });

    testWidgets('picks another barcode type', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Loyalty');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarcodeTypeSelectorButton));
      await tester.pumpAndSettle();
      await tester.scrollToAndTap(find.widgetWithText(ListTile, 'QR-Code'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CardDataFormField),
        'anything goes in a qr code',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      final stored = loyaltyCardsBox.values.single;
      expect(stored.barcode.type, BarcodeType.QrCode);
      expect(
        stored.barcode.data,
        'anything goes in a qr code',
        reason: 'a qr code is not checked the way a barcode is',
      );
    });
  });

  group('a card which cannot be saved', () {
    testWidgets('says the name is missing', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(snackBarText(tester), 'Card Name cannot be empty!');
      expect(loyaltyCardsBox.values, isEmpty);
    });

    testWidgets('says the number is missing once a type is picked',
        (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarcodeTypeSelectorButton));
      await tester.pumpAndSettle();
      await tester.scrollToAndTap(find.widgetWithText(ListTile, 'EAN-13'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(snackBarText(tester), 'Card ID cannot be empty!');
      expect(loyaltyCardsBox.values, isEmpty);
    });

    testWidgets('says the number is not a barcode', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarcodeTypeSelectorButton));
      await tester.pumpAndSettle();
      await tester.scrollToAndTap(find.widgetWithText(ListTile, 'EAN-13'));
      await tester.pumpAndSettle();
      // thirteen digits, but the last one does not add up.
      await tester.enterText(find.byType(CardDataFormField), '9780201379625');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      expect(snackBarText(tester), 'Invalid Card ID!');
      expect(loyaltyCardsBox.values, isEmpty);
    });

    testWidgets('shows what is wrong on the field itself', (tester) async {
      // ARRANGE
      await openNewCardForm(tester);

      // ACT
      await tester.enterText(find.byType(CardNameFormField), 'Delhaize');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarcodeTypeSelectorButton));
      await tester.pumpAndSettle();
      await tester.scrollToAndTap(find.widgetWithText(ListTile, 'EAN-13'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CardDataFormField), '123');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Value must have length 13'), findsOneWidget);
    });
  });

  group('editing a card which exists', () {
    testWidgets('changes it instead of adding another one', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'card-under-test',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'card-under-test',
              name: 'Delhaize',
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN13),
            ),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await openCardMenu(tester, 'Delhaize');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldWithLabel('Card Name'), 'Delhaize City');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SaveButton));
      await tester.pumpAndSettle();

      // ASSERT
      expect(
        loyaltyCardsBox.values.map((card) => card.name),
        ['Delhaize City'],
      );
      expect(
        loyaltyCardsBox.values.single.id,
        'card-under-test',
        reason: 'it is the same card',
      );
      expect(find.text('Delhaize City'), findsOneWidget);
    });

    testWidgets('shows the card which is being edited', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              notes: 'The one on the corner',
              points: 12,
              usePoints: true,
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN8),
            ),
      );
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();

      // ACT
      await openCardMenu(tester, 'Delhaize');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(fieldText(tester, 'Card Name'), 'Delhaize');
      expect(fieldText(tester, 'Card ID'), validEan13);
      expect(find.text('EAN-8'), findsOneWidget);
    });

    testWidgets('leaves the card alone when the form is left', (tester) async {
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
      await tester.enterText(fieldWithLabel('Card Name'), 'Something else');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();

      // ASSERT
      expect(loyaltyCardsBox.values.map((card) => card.name), ['Delhaize']);
    });
  });
}
