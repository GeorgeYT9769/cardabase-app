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
          input: '[{"id":"test-id-1","barcode":{"data":"123","type":"Code128"},"name":"Δημοτική Βιβλιοθήκη","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z","notes":"Greek library card"}]',
          expectedShopNames: ['Δημοτική Βιβλιοθήκη'],
        ),
        DeserializeLoyaltyCardsTestCase(
          name: 'JSON export with mixed valid and invalid cards (recovers valid cards)',
          input: '[{"id":"test-id-1","barcode":{"data":"123","type":"Code128"},"name":"Valid Card","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z"},{"id":"test-id-2","barcode":null,"name":"Invalid Card","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z"},{"id":"test-id-3","barcode":{"data":"456","type":"CodeEAN13"},"name":"Another Valid","createdAt":"2026-06-15T12:00:00.000Z","lastModifiedAt":"2026-06-15T12:00:00.000Z"}]',
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
