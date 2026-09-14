import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart' as widget;
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/main.dart';
import 'package:cardabase/pages/home/home_page.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import '../../../test_helpers/fakers/loyalty_card.dart';
import '../../app_harness.dart';

void main() => testCardDetailsPage();

void testCardDetailsPage() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final validEan13 = faker.loyaltyCards.codeEAN13();

  useApp();

  group('opening a card', () {
    testWidgets('shows the barcode of the card', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              points: 12,
              usePoints: true,
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN13),
            ),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delhaize'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Delhaize'), findsWidgets);
      expect(find.text('12 points'), findsOneWidget);
      final barcode = tester
          .widget<widget.BarcodeWidget>(find.byType(widget.BarcodeWidget));
      expect(utf8.decode(barcode.data), validEan13);
      expect(barcode.barcode.name, widget.Barcode.ean13().name);
    });

    testWidgets('shows the notes of the card', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              notes: 'The one on the corner',
            ),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delhaize'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('The one on the corner'), findsOneWidget);
    });

    testWidgets('goes back to the cards', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards
            .simpleCard()
            .copyWith(id: 'delhaize', name: 'Delhaize'),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delhaize'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Cardabase'), findsOneWidget);
    });

    testWidgets('shares the card as a code', (tester) async {
      // ARRANGE
      usePhoneView(tester);
      final loyaltyCardsBox = await GetIt.I.getAsync<LoyaltyCardsBox>();
      await loyaltyCardsBox.put(
        'delhaize',
        faker.loyaltyCards.simpleCard().copyWith(
              id: 'delhaize',
              name: 'Delhaize',
              barcode: Barcode(data: validEan13, type: BarcodeType.CodeEAN13),
            ),
      );

      // ACT
      await tester.pumpWidget(Main(initialScreen: Homepage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delhaize'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.qr_code_2));
      await tester.pumpAndSettle();

      // ASSERT the card is shared as the json another phone can scan.
      final codes = tester
          .widgetList<widget.BarcodeWidget>(find.byType(widget.BarcodeWidget))
          .map((barcode) => utf8.decode(barcode.data))
          .where((data) => data.startsWith('{'));
      expect(codes, isNotEmpty, reason: 'the card should be shown as a code');
      expect(codes.first, contains('Delhaize'));
      expect(codes.first, contains(validEan13));
    });
  });
}
