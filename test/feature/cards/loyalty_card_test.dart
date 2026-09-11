import 'dart:ui';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_helpers/input_output_test_case.dart';
import '../../../test_helpers/matchers/is_between.dart';
import '../../../test_helpers/matchers/loyalty_card.dart';

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
            usePoints: false,
          ),
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          // ARRANGE
          final start = DateTime.now().toUtc();

          // ACT
          final output = LoyaltyCard.fromLegacySharing(tc.input);

          // ARRANGE
          final end = DateTime.now().toUtc();

          expect(
            output,
            loyaltyCard(
              expected: tc.expected,
              // the id should be recalculated and thus not be the provided id
              id: isNot(tc.expected.id),
              createdAt: isBetween(start, end),
              lastModifiedAt: isBetween(start, end),
            ),
          );
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
            usePoints: false,
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
            usePoints: true,
          ),
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          // ARRANGE
          final start = DateTime.now().toUtc();

          // ACT
          final output = LoyaltyCard.fromLegacyExport(tc.input);

          // ARRANGE
          final end = DateTime.now().toUtc();

          expect(
            output,
            loyaltyCard(
              expected: tc.expected,
              // the id should be recalculated and thus not be the provided id
              id: isNot(tc.expected.id),
              createdAt: isBetween(start, end),
              lastModifiedAt: isBetween(start, end),
            ),
          );
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
            usePoints: false,
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
            'usePoints': false,
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
            usePoints: false,
          ),
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () {
          // ARRANGE
          final start = DateTime.now().toUtc();

          // ACT
          final output = LoyaltyCard.fromJsonMap(tc.input);

          // ARRANGE
          final end = DateTime.now().toUtc();

          expect(
            output,
            loyaltyCard(
              expected: tc.expected,
              id: isNotEmpty,
              createdAt: isBetween(start, end),
              lastModifiedAt: isBetween(start, end),
            ),
          );
        });
      }
    });

    test('id should be taken over when provided', () {
      // ARRANGE
      final input = {
        'id': '6fdfeb5a-04d9-4134-bade-7e5a53c3b268',
        'name': 'Shop 1',
        'barcode': {
          'data': 'this is a test value',
          'type': 'QrCode',
        },
      };
      final expected = LoyaltyCard(
        id: '6fdfeb5a-04d9-4134-bade-7e5a53c3b268',
        barcode: const Barcode(
          data: 'this is a test value',
          type: BarcodeType.QrCode,
        ),
        name: 'Shop 1',
        color: null,
        tags: {},
        notes: null,
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        points: 0,
        requiresAuth: false,
        hideName: false,
        createdAt: DateTime.now().toUtc(),
        lastModifiedAt: DateTime.now().toUtc(),
        usePoints: false,
      );
      final start = DateTime.now().toUtc();

      // ACT
      final output = LoyaltyCard.fromJsonMap(input);

      // ARRANGE
      final end = DateTime.now().toUtc();

      expect(
        output,
        loyaltyCard(
          expected: expected,
          createdAt: isBetween(start, end),
          lastModifiedAt: isBetween(start, end),
        ),
      );
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
            createdAt: DateTime.parse('2026-05-26T19:42:35.324Z'),
            lastModifiedAt: DateTime.parse('2026-05-26T19:42:36.324Z'),
            usePoints: false,
          ),
          expected: {
            'id': 'c587625b-6892-428d-b902-f39e5b29edf1',
            'name': 'Shop 1',
            'barcode': {
              'data': 'this is a test value',
              'type': 'QrCode',
            },
            'createdAt': '2026-05-26T19:42:35.324Z',
            'lastModifiedAt': '2026-05-26T19:42:36.324Z',
            'points': 0,
            'usePoints': false,
            'usedCount': 0,
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
            createdAt: DateTime.parse('2026-05-26T19:42:35.324Z'),
            lastModifiedAt: DateTime.parse('2026-05-26T19:42:36.324Z'),
            usePoints: true,
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
            'createdAt': '2026-05-26T19:42:35.324Z',
            'lastModifiedAt': '2026-05-26T19:42:35.324Z',
            'usePoints': false,
            'usedCount': 0,
          },
        ),
        InputOutputTestCase(
          name: 'usePoints is true',
          input: LoyaltyCard(
            id: 'test-id',
            barcode: const Barcode(
              data: '123',
              type: BarcodeType.QrCode,
            ),
            name: 'Shop 3',
            color: null,
            tags: const {},
            notes: null,
            frontImagePath: null,
            backImagePath: null,
            useFrontImageOverlay: false,
            points: 10,
            requiresAuth: false,
            hideName: false,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(1779824555324).toUtc(),
            lastModifiedAt:
                DateTime.fromMillisecondsSinceEpoch(1779824555324).toUtc(),
            usePoints: true,
          ),
          expected: {
            'id': 'test-id',
            'name': 'Shop 3',
            'barcode': {
              'data': '123',
              'type': 'QrCode',
            },
            'createdAt': '2026-05-26T19:42:35.324Z',
            'lastModifiedAt': '2026-05-26T19:42:35.324Z',
            'points': 10,
            'usePoints': true,
            'usedCount': 0,
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

  group('fromJsonMap', () {
    group('not ok', () {
      test('throws without a name', () {
        expect(
          () => LoyaltyCard.fromJsonMap({
            'barcode': {'data': '123'},
          }),
          throwsA(isA<Exception>()),
        );
      });

      test('throws without a barcode', () {
        expect(
          () => LoyaltyCard.fromJsonMap({'name': 'Shop 1'}),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('Barcode', () {
    test('writes and reads its json', () {
      const barcode = Barcode(data: '123', type: BarcodeType.QrCode);

      final restored = Barcode.fromJsonMap(barcode.toJsonMap());

      expect(restored.data, barcode.data);
      expect(restored.type, barcode.type);
    });

    test('leaves the type out when the card has none', () {
      const barcode = Barcode(data: '123', type: null);

      expect(barcode.toJsonMap(), {'data': '123'});
      expect(Barcode.fromJsonMap(barcode.toJsonMap()).type, isNull);
    });

    test('throws for json without data', () {
      expect(
        () => Barcode.fromJsonMap({'type': 'CodeEAN13'}),
        throwsA(isA<Exception>()),
      );
    });

    test('throws for a type it does not know', () {
      expect(
        () => Barcode.fromJsonMap({'data': '123', 'type': 'smoke signal'}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
