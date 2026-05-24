import 'dart:ui';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'fromLegacySharing',
    () {
      group('ok', () {
        final testCases = [
          FromLegacySharingTestCase(
            name: 'no optional values',
            input:
                '{cardName: Shop 1 , cardId: 2297772559224, cardType: CardType.ean13, uniqueId: 20251230173039, }',
            expected: LoyaltyCard(
              id: '20251230173039',
              barcode: const Barcode(
                data: '2297772559224',
                type: BarcodeType.CodeEAN13,
              ),
              name: 'Shop 1',
              color: null,
              tags: const {},
              notes: null,
              frontImagePath: null,
              backImagePath: null,
              useFrontImageOverlay: false,
              points: 0,
              requiresAuth: false,
              hideName: false,
              createdAt: DateTime.now().toUtc(),
              lastModifiedAt: DateTime.now().toUtc(),
            ),
          ),
          FromLegacySharingTestCase(
            name: 'all optional values',
            input:
                '{cardName: Shop 2 , cardId: 2297772559224, redValue: 0, greenValue: 79, blueValue: 155, cardType: CardType.ean13, hasPassword: true, uniqueId: 20251230173038, note: this is my special note, pointsAmount: 12 }',
            expected: LoyaltyCard(
              id: '20251230173038',
              barcode: const Barcode(
                data: '2297772559224',
                type: BarcodeType.CodeEAN13,
              ),
              name: 'Shop 2',
              color: Color.fromARGB(255, 0, 79, 155),
              tags: const {},
              notes: 'this is my special note',
              frontImagePath: null,
              backImagePath: null,
              useFrontImageOverlay: false,
              points: 12,
              requiresAuth: true,
              hideName: false,
              createdAt: DateTime.now().toUtc(),
              lastModifiedAt: DateTime.now().toUtc(),
            ),
          ),
        ];

        for (final tc in testCases) {
          test(tc.name, () {
            // ACT
            final output = LoyaltyCard.fromLegacyExport(tc.input);

            // ARRANGE
            // the id should be recalculated and thus not be the provided id
            expect(output.id, isNot(tc.expected.id));
            expect(output.barcode.data, tc.expected.barcode.data);
            expect(output.barcode.type, tc.expected.barcode.type);
            expect(output.name, tc.expected.name);
            expect(output.color, tc.expected.color);
            expect(output.tags, tc.expected.tags);
            expect(output.notes, tc.expected.notes);
            expect(output.frontImagePath, tc.expected.frontImagePath);
            expect(output.backImagePath, tc.expected.backImagePath);
            expect(
                output.useFrontImageOverlay, tc.expected.useFrontImageOverlay);
            expect(output.points, tc.expected.points);
            expect(output.requiresAuth, tc.expected.requiresAuth);
            expect(output.hideName, tc.expected.hideName);
          });
        }
      });
    },
  );
}

class FromLegacySharingTestCase {
  const FromLegacySharingTestCase({
    required this.name,
    required this.input,
    required this.expected,
  });

  final String name;
  final String input;
  final LoyaltyCard expected;
}
