import 'dart:io';
import 'dart:ui';

import 'package:cardabase/feature/cards/barcode_type_type_adapter.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/migrations.dart';
import 'package:cardabase/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart' show ColorAdapter;

void main() {
  late Directory tempDir;

  setUpAll(() {
    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(const BarcodeTypeAdapter());
    Hive.registerAdapters();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cardabase_migrations');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('migrateCardsBoxTo202603', () {
    var boxCounter = 0;

    Future<List<LoyaltyCard>> runMigrationsFor(oldCards) async {
      boxCounter++;
      final oldBox =
          await Hive.openBox('migrateCardsBoxTo202603_old_$boxCounter');
      await oldBox.put('CARDLIST', oldCards);
      final newBox = await Hive.openBox<LoyaltyCard>(
        'migrateCardsBoxTo202603_new_$boxCounter',
      );

      await migrateCardsBoxTo202603(oldBox, newBox);
      return newBox.values.toList(growable: false);
    }

    group('cards stored as a list of loose values', () {
      test('are migrated instead of dropped', () async {
        // ACT
        final cards = await runMigrationsFor([
          ['Shop 1', '2297772559224', 0, 79, 155, 'CardType.ean13', false],
        ]);

        // ASSERT
        expect(cards, hasLength(1));
        final card = cards.single;
        expect(card.name, 'Shop 1');
        expect(card.barcode.data, '2297772559224');
        expect(card.barcode.type, BarcodeType.CodeEAN13);
        expect(card.color, const Color.fromARGB(255, 0, 79, 155));
        expect(card.requiresAuth, isFalse);
      });

      test('keep the cards which can be read when one of them cannot',
          () async {
        // ACT
        final cards = await runMigrationsFor([
          ['Shop 1', '2297772559224', 0, 79, 155, 'CardType.ean13', false],
          // too few values to be a card
          ['Shop 2', '123'],
          ['Shop 3', '4006381333931', 1, 2, 3, 'CardType.ean13', true],
        ]);

        // ASSERT
        // the order in the box follows the generated ids, not the input.
        expect(
          cards.map((card) => card.name),
          unorderedEquals(['Shop 1', 'Shop 3']),
        );
      });

      test('read the password flag', () async {
        // ACT
        final cards = await runMigrationsFor([
          ['Shop 1', '2297772559224', 0, 79, 155, 'CardType.ean13', true],
        ]);

        // ASSERT
        expect(cards.single.requiresAuth, isTrue);
      });

      test('keeps the value as it was stored', () async {
        // ACT
        final cards = await runMigrationsFor([
          [' Shop 1 ', '2297772559224', 0, 79, 155, 'CardType.ean13', false],
        ]);

        // ASSERT
        expect(cards.single.name, ' Shop 1 ');
      });

      test('keeps a name which contains a comma', () async {
        // ACT
        final cards = await runMigrationsFor([
          [
            'Shop 1, Antwerp',
            '2297772559224',
            0,
            79,
            155,
            'CardType.ean13',
            false,
          ],
        ]);

        // ASSERT
        expect(cards.single.name, 'Shop 1, Antwerp');
        expect(cards.single.barcode.data, '2297772559224');
      });

      test('a null value does not drop the card', () async {
        // ACT
        final cards = await runMigrationsFor([
          ['Shop 1', '2297772559224', 0, 79, 155, 'CardType.ean13', null],
        ]);

        // ASSERT
        expect(cards, hasLength(1));
        expect(cards.single.name, 'Shop 1');
        expect(
          cards.single.requiresAuth,
          isFalse,
          reason: 'a null password flag is not an enabled password',
        );
      });

      test('a null barcode type keeps the card without a type', () async {
        // ACT
        final cards = await runMigrationsFor([
          ['Shop 1', '2297772559224', 0, 79, 155, null, false],
        ]);

        // ASSERT
        expect(cards.single.name, 'Shop 1');
        expect(cards.single.barcode.type, isNull);
      });
    });

    test('does not overwrite cards which are already migrated', () async {
      // ARRANGE
      boxCounter++;
      final oldBox = await Hive.openBox<dynamic>('old_$boxCounter');
      await oldBox.put('CARDLIST', [
        ['Shop 1', '2297772559224', 0, 79, 155, 'CardType.ean13', false],
      ]);
      final newBox = await Hive.openBox<LoyaltyCard>('new_$boxCounter');
      final now = DateTime.now().toUtc();
      await newBox.put(
        'existing',
        LoyaltyCard(
          id: 'existing',
          barcode: const Barcode(data: '123', type: BarcodeType.Code128),
          name: 'Already migrated',
          color: null,
          tags: const {},
          notes: null,
          frontImagePath: null,
          backImagePath: null,
          useFrontImageOverlay: false,
          points: 0,
          requiresAuth: false,
          hideName: false,
          createdAt: now,
          lastModifiedAt: now,
          usePoints: false,
        ),
      );

      // ACT
      await migrateCardsBoxTo202603(oldBox, newBox);

      // ASSERT
      expect(newBox.values.map((card) => card.name), ['Already migrated']);
    });
  });
}
