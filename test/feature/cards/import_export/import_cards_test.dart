import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/feature/cards/import_export/import_cards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deserializeLoyaltyCards', () {
    group('ok', () {
      final testCases = [
        DeserializeLoyaltyCardsTestCase(
          name: 'simple export',
          input: '''
If you do not know what are you doing, please do not touch this file. One mistake and you can lose all your data! Copy everything under === line and paste them into import window.
Timestamp: 20260524155619
=======================================================================
{cardName: Shop 1 , cardType: CardType.ean13, }
{cardName: Pretty Plaza , cardType: CardType.ean13, }
{cardName: Hotel California, cardType: CardType.ean13, }
{cardName: Gizmos inc. , cardType: CardType.ean13, }
{cardName: Dollar store , cardType: CardType.code128, }
''',
          expectedShopNames: [
            'Shop 1',
            'Pretty Plaza',
            'Hotel California',
            'Gizmos inc.',
            'Dollar store',
          ],
        ),
        DeserializeLoyaltyCardsTestCase(
          name: 'JSON export with non-Latin characters',
          input:
              '[{"id":"test-id-1","barcode":{"data":"123","type":"Code128"},"name":"Δημοτική Βιβλιοθήκη","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z","notes":"Greek library card"}]',
          expectedShopNames: ['Δημοτική Βιβλιοθήκη'],
        ),
        DeserializeLoyaltyCardsTestCase(
          name:
              'JSON export with mixed valid and invalid cards (recovers valid cards)',
          input:
              '[{"id":"test-id-1","barcode":{"data":"123","type":"Code128"},"name":"Valid Card","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z"},{"id":"test-id-2","barcode":null,"name":"Invalid Card","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z"},{"id":"test-id-3","barcode":{"data":"456","type":"CodeEAN13"},"name":"Another Valid","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z"}]',
          expectedShopNames: ['Valid Card', 'Another Valid'],
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          final output = deserializeLoyaltyCards(tc.input);
          expect(output.length, tc.expectedShopNames.length);
          expect(
            output.map((card) => card.name),
            containsAll(tc.expectedShopNames),
          );
        });
      }
    });

    group('cards which need care', () {
      test('imports a legacy card of the oldest, list shape', () {
        // ARRANGE
        final legacyShare =
            '[Legacy Card, 9780201379624, 158, 158, 158, CardType.ean13, false]';

        // ACT
        final cards = deserializeLoyaltyCards(legacyShare);

        // ASSERT
        expect(cards, hasLength(1));
        expect(cards.single.name, 'Legacy Card');
        expect(cards.single.barcode.data, '9780201379624');
        expect(cards.single.barcode.type, BarcodeType.CodeEAN13);
      });

      test('imports a legacy card which carries no barcode type', () {
        // an old export wrote the key even for a card which had none, and
        // dropping such a card would lose it on import.

        // ARRANGE
        final input = '{cardName: Shop 1, cardId: 9780201379624, cardType: }\n'
            '{cardName: Shop 2, cardId: 4006381333931}';

        // ACT
        final cards = deserializeLoyaltyCards(input);

        // ASSERT
        expect(cards, hasLength(2));
        expect(cards.map((card) => card.name), ['Shop 1', 'Shop 2']);
        expect(cards.every((card) => card.barcode.type == null), isTrue);
      });

      test('gives every imported legacy card an id of its own', () {
        // ARRANGE
        final input = '{cardName: Shop 1, cardId: 9780201379624}\n'
            '{cardName: Shop 2, cardId: 4006381333931}';

        // ACT
        final cards = deserializeLoyaltyCards(input);

        // ASSERT
        final ids = cards.map((card) => card.id).toSet();
        expect(
          ids,
          hasLength(2),
          reason: 'two cards sharing an id would overwrite each other',
        );
      });

      test('finds nothing in a text which holds no cards', () {
        expect(
          deserializeLoyaltyCards('there are no cards in this text'),
          isEmpty,
        );
        expect(deserializeLoyaltyCards(''), isEmpty);
        expect(deserializeLoyaltyCards('[]'), isEmpty);
      });
    });
  });
}

class DeserializeLoyaltyCardsTestCase {
  const DeserializeLoyaltyCardsTestCase({
    required this.name,
    required this.input,
    required this.expectedShopNames,
  });

  final String name;
  final String input;
  final List<String> expectedShopNames;
}
