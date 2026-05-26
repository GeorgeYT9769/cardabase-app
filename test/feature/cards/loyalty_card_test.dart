import 'dart:ui';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/input_output_test_case.dart';

void main() {
  group('fromLegacySharing', () {
    group('ok', () {
      final testCases = [
        InputOutputTestCase(
          name: 'simple',
          input:
              '[Shop 1, 2297772559224, 0, 79, 155, CardType.ean13, false, []]',
          expected: LoyaltyCard(
            id: '20251230173039',
            barcode: const Barcode(
              data: '2297772559224',
              type: BarcodeType.CodeEAN13,
            ),
            name: 'Shop 1',
            color: Color.fromARGB(255, 0, 79, 155),
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
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          // ACT
          final output = LoyaltyCard.fromLegacySharing(tc.input);

          // ARRANGE
          expect(
            output.id,
            isNot(tc.expected.id),
            reason:
                'the id should be recalculated and thus not be the provided id',
          );
          expect(output.barcode.data, tc.expected.barcode.data);
          expect(output.barcode.type, tc.expected.barcode.type);
          expect(output.name, tc.expected.name);
          expect(output.color, tc.expected.color);
          expect(output.tags, tc.expected.tags);
          expect(output.notes, tc.expected.notes);
          expect(output.frontImagePath, tc.expected.frontImagePath);
          expect(output.backImagePath, tc.expected.backImagePath);
          expect(output.useFrontImageOverlay, tc.expected.useFrontImageOverlay);
          expect(output.points, tc.expected.points);
          expect(output.requiresAuth, tc.expected.requiresAuth);
          expect(output.hideName, tc.expected.hideName);
        });
      }
    });
  });

  group('fromLegacyExport', () {
    group('ok', () {
      final testCases = [
        InputOutputTestCase(
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
        InputOutputTestCase(
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
          expect(
            output.id,
            isNot(tc.expected.id),
            reason:
                'the id should be recalculated and thus not be the provided id',
          );
          expect(output.barcode.data, tc.expected.barcode.data);
          expect(output.barcode.type, tc.expected.barcode.type);
          expect(output.name, tc.expected.name);
          expect(output.color, tc.expected.color);
          expect(output.tags, tc.expected.tags);
          expect(output.notes, tc.expected.notes);
          expect(output.frontImagePath, tc.expected.frontImagePath);
          expect(output.backImagePath, tc.expected.backImagePath);
          expect(output.useFrontImageOverlay, tc.expected.useFrontImageOverlay);
          expect(output.points, tc.expected.points);
          expect(output.requiresAuth, tc.expected.requiresAuth);
          expect(output.hideName, tc.expected.hideName);
        });
      }
    });
  });

  group('fromJsonMap', () {
    group('ok', () {
      final testCases = [
        InputOutputTestCase(
          name: 'no optional values',
          input: {
            'name': 'Shop 1',
            'barcode': {
              'data': 'this is a test value',
              'type': 'QrCode',
            },
          },
          expected: LoyaltyCard(
            id: '',
            barcode: const Barcode(
              data: 'this is a test value',
              type: BarcodeType.QrCode,
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
        InputOutputTestCase(
          name: 'all optional values',
          input: {
            'id': '6fdfeb5a-04d9-4134-bade-7e5a53c3b268',
            'barcode': {
              'data': '1234567890',
              'type': 'QrCode',
            },
            'name': 'Shop 2',
            'color': '#FF123456',
            'tags': ['tag1', 'some other tag'],
            'notes': 'this is my special note',
            'useFrontImageOverlay': true,
            'points': 42,
            'requiresAuth': true,
            'hideName': true,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
          expected: LoyaltyCard(
            id: '6fdfeb5a-04d9-4134-bade-7e5a53c3b268',
            barcode: const Barcode(
              data: '1234567890',
              type: BarcodeType.QrCode,
            ),
            name: 'Shop 2',
            color: Color.fromARGB(255, 0x12, 0x34, 0x56),
            tags: const {'tag1', 'some other tag'},
            notes: 'this is my special note',
            frontImagePath: null,
            backImagePath: null,
            useFrontImageOverlay: true,
            points: 42,
            requiresAuth: true,
            hideName: true,
            createdAt: DateTime.now().toUtc(),
            lastModifiedAt: DateTime.now().toUtc(),
          ),
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          // ACT
          final output = LoyaltyCard.fromJsonMap(tc.input);

          // ARRANGE
          expect(output.id, isNotEmpty);
          expect(output.barcode.data, tc.expected.barcode.data);
          expect(output.barcode.type, tc.expected.barcode.type);
          expect(output.name, tc.expected.name);
          expect(output.color, tc.expected.color);
          expect(output.tags, tc.expected.tags);
          expect(output.notes, tc.expected.notes);
          expect(output.frontImagePath, tc.expected.frontImagePath);
          expect(output.backImagePath, tc.expected.backImagePath);
          expect(output.useFrontImageOverlay, tc.expected.useFrontImageOverlay);
          expect(output.points, tc.expected.points);
          expect(output.requiresAuth, tc.expected.requiresAuth);
          expect(output.hideName, tc.expected.hideName);
        });
      }
    });
  });

  group('toJsonMap', () {
    group('ok', () {
      final testCases = [
        InputOutputTestCase(
          name: 'no optional values',
          input: LoyaltyCard(
            id: 'c587625b-6892-428d-b902-f39e5b29edf1',
            barcode: const Barcode(
              data: 'this is a test value',
              type: BarcodeType.QrCode,
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
            createdAt: DateTime.fromMillisecondsSinceEpoch(1779824555324),
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(1779824555324),
          ),
          expected: {
            'id': 'c587625b-6892-428d-b902-f39e5b29edf1',
            'name': 'Shop 1',
            'barcode': {
              'data': 'this is a test value',
              'type': 'QrCode',
            },
            'createdAt': '2026-05-26T21:42:35.324',
            'lastModifiedAt': '2026-05-26T21:42:35.324',
          },
        ),
        InputOutputTestCase(
          name: 'all optional values',
          input: LoyaltyCard(
            id: '6fdfeb5a-04d9-4134-bade-7e5a53c3b268',
            barcode: const Barcode(
              data: '1234567890',
              type: BarcodeType.QrCode,
            ),
            name: 'Shop 2',
            color: Color.fromARGB(255, 0x12, 0x34, 0x56),
            tags: const {'tag1', 'some other tag'},
            notes: 'this is my special note',
            frontImagePath: null,
            backImagePath: null,
            useFrontImageOverlay: true,
            points: 42,
            requiresAuth: true,
            hideName: true,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1779824555324),
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(1779824555324),
          ),
          expected: {
            'id': '6fdfeb5a-04d9-4134-bade-7e5a53c3b268',
            'barcode': {
              'data': '1234567890',
              'type': 'QrCode',
            },
            'name': 'Shop 2',
            'color': 'FF123456',
            'tags': ['tag1', 'some other tag'],
            'notes': 'this is my special note',
            'useFrontImageOverlay': true,
            'points': 42,
            'requiresAuth': true,
            'hideName': true,
            'createdAt': '2026-05-26T21:42:35.324',
            'lastModifiedAt': '2026-05-26T21:42:35.324',
          },
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          // ACT
          final output = tc.input.toJsonMap();

          // ARRANGE
          expect(output, equals(tc.expected));
        });
      }
    });
  });
}
