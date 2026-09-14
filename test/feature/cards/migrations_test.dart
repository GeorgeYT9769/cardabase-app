import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/migrations.dart';
import 'package:faker/faker.dart' hide Color;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../../test_helpers/fakers/loyalty_card.dart';
import '../../../test_helpers/hive.dart';

void main() {
  final validEan13 = faker.loyaltyCards.codeEAN13();
  final otherValidEan13 = faker.loyaltyCards.codeEAN13();

  group('migrateCardsBoxTo202603', () {
    useHive();

    /// The box the older versions of the app stored their cards in.
    late Box oldBox;

    setUp(() async {
      oldBox = await Hive.openBox('mybox');
      await oldBox.clear();
    });

    tearDown(() => oldBox.close());

    /// A card the way the old app wrote it: a map of loose values.
    Map<String, dynamic> legacyCard({
      String name = 'Delhaize',
      String? data,
      String? cardType = 'CardType.ean13',
      int? red = 1,
      int? green = 2,
      int? blue = 3,
      bool hasPassword = false,
      String uniqueId = '20240101120000',
      List<String> tags = const [],
      String? note,
      int? pointsAmount,
    }) {
      return {
        'cardName': name,
        'cardId': data ?? validEan13,
        if (cardType != null) 'cardType': cardType,
        if (red != null) 'redValue': red,
        if (green != null) 'greenValue': green,
        if (blue != null) 'blueValue': blue,
        'hasPassword': hasPassword,
        'uniqueId': uniqueId,
        'tags': tags,
        if (note != null) 'note': note,
        if (pointsAmount != null) 'pointsAmount': pointsAmount,
      };
    }

    test('carries the cards of an older version over', () async {
      await oldBox.put('CARDLIST', [
        legacyCard(name: 'Delhaize', uniqueId: '1'),
        legacyCard(name: 'Colruyt', data: otherValidEan13, uniqueId: '2'),
      ]);

      await migrateCardsBoxTo202603(oldBox, cardsBox());

      expect(storedCardNames(), containsAll(['Delhaize', 'Colruyt']));
      expect(storedCards(), hasLength(2));
    });

    test('carries every field of a card over', () async {
      await oldBox.put('CARDLIST', [
        legacyCard(
          name: 'Delhaize',
          data: validEan13,
          cardType: 'CardType.qrcode',
          red: 1,
          green: 2,
          blue: 3,
          hasPassword: true,
          uniqueId: '20240101120000',
          tags: ['groceries'],
          note: 'The one on the corner',
          pointsAmount: 42,
        ),
      ]);

      await migrateCardsBoxTo202603(oldBox, cardsBox());

      final card = storedCards().single;
      expect(card.id, '20240101120000');
      expect(card.name, 'Delhaize');
      expect(card.barcode.data, validEan13);
      expect(card.barcode.type, BarcodeType.QrCode);
      expect(card.color, const Color.fromARGB(255, 1, 2, 3));
      expect(card.requiresAuth, isTrue);
      expect(card.tags, {'groceries'});
      expect(card.notes, 'The one on the corner');
      expect(card.points, 42);
    });

    test('keeps a card which was stored without a colour', () async {
      await oldBox.put('CARDLIST', [
        legacyCard(name: 'No colour', red: null, green: null, blue: null),
      ]);

      await migrateCardsBoxTo202603(oldBox, cardsBox());

      expect(storedCards().single.color, isNull);
    });

    test('keeps a card of the oldest, list-shaped format', () async {
      await oldBox.put('CARDLIST', [
        ['Legacy Card', validEan13, 158, 158, 158, 'CardType.ean13', false],
      ]);

      await migrateCardsBoxTo202603(oldBox, cardsBox());

      expect(storedCardNames(), ['Legacy Card']);
      expect(storedCards().single.barcode.data, validEan13);
    });

    group('a card of the oldest, list-shaped format', () {
      test('carries its every value over', () async {
        await oldBox.put('CARDLIST', [
          ['Legacy Card', validEan13, 0, 79, 155, 'CardType.ean13', true],
        ]);

        await migrateCardsBoxTo202603(oldBox, cardsBox());

        final card = storedCards().single;
        expect(card.name, 'Legacy Card');
        expect(card.barcode.data, validEan13);
        expect(card.barcode.type, BarcodeType.CodeEAN13);
        expect(card.color, const Color.fromARGB(255, 0, 79, 155));
        expect(card.requiresAuth, isTrue);
      });

      test('keeps a name which contains a comma', () async {
        await oldBox.put('CARDLIST', [
          ['Shop 1, Antwerp', validEan13, 0, 79, 155, 'CardType.ean13', false],
        ]);

        await migrateCardsBoxTo202603(oldBox, cardsBox());

        expect(storedCardNames(), ['Shop 1, Antwerp']);
        expect(storedCards().single.barcode.data, validEan13);
      });

      test('keeps the name as it was stored', () async {
        await oldBox.put('CARDLIST', [
          [' Legacy Card ', validEan13, 0, 79, 155, 'CardType.ean13', false],
        ]);

        await migrateCardsBoxTo202603(oldBox, cardsBox());

        expect(storedCardNames(), [' Legacy Card ']);
      });

      test('is not dropped because its password flag is null', () async {
        await oldBox.put('CARDLIST', [
          ['Legacy Card', validEan13, 0, 79, 155, 'CardType.ean13', null],
        ]);

        await migrateCardsBoxTo202603(oldBox, cardsBox());

        expect(storedCardNames(), ['Legacy Card']);
        expect(
          storedCards().single.requiresAuth,
          isFalse,
          reason: 'a null password flag is not an enabled password',
        );
      });

      test('is kept without a type when its type is null', () async {
        await oldBox.put('CARDLIST', [
          ['Legacy Card', validEan13, 0, 79, 155, null, false],
        ]);

        await migrateCardsBoxTo202603(oldBox, cardsBox());

        expect(storedCardNames(), ['Legacy Card']);
        expect(storedCards().single.barcode.type, isNull);
      });

      test('does not take the readable cards down with it', () async {
        await oldBox.put('CARDLIST', [
          ['Legacy Card', validEan13, 0, 79, 155, 'CardType.ean13', false],
          // too few values to be a card
          ['Half a card', '123'],
          ['Other Card', otherValidEan13, 1, 2, 3, 'CardType.ean13', true],
        ]);

        await migrateCardsBoxTo202603(oldBox, cardsBox());

        expect(
          storedCardNames(),
          unorderedEquals(['Legacy Card', 'Other Card']),
        );
      });
    });

    test('leaves the cards alone when there are already new ones', () async {
      await storeCards([
        faker.loyaltyCards.card().copyWith(name: 'Already migrated'),
      ]);
      await oldBox.put('CARDLIST', [legacyCard(name: 'Delhaize')]);

      await migrateCardsBoxTo202603(oldBox, cardsBox());

      expect(storedCardNames(), ['Already migrated']);
    });

    test('does nothing when there is nothing to migrate', () async {
      await migrateCardsBoxTo202603(oldBox, cardsBox());

      expect(storedCards(), isEmpty);
    });

    test('does not lose a card because another one cannot be read', () async {
      await oldBox.put('CARDLIST', [
        'this is not a card',
        legacyCard(name: 'Delhaize'),
      ]);

      await migrateCardsBoxTo202603(oldBox, cardsBox());

      expect(storedCardNames(), ['Delhaize']);
    });
  });
}
