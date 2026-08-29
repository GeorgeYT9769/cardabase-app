import 'dart:convert';

import 'package:cardabase/feature/cards/import_export/export_cards.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_helpers/fakers/loyalty_card.dart';
import '../../../../test_helpers/mocks/plugins/clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('exportCardsToClipboard', () {
    late MockClipboardPlatform clipboard;

    setUp(() {
      clipboard = createMockClipboardPlatform(
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
      );
    });

    test('copies the cards as json', () async {
      // ARRANGE
      final cards = [
        faker.loyaltyCards.card(),
        faker.loyaltyCards.card(),
        faker.loyaltyCards.card(),
      ];
      final expectedList = cards.map((card) => card.toJsonMap()).toList();

      // ACT
      await exportCardsToClipboard(cards);

      // ASSERT
      expect(clipboard.clipboardText, isNotNull);
      final decoded = jsonDecode(clipboard.clipboardText!);
      expect(decoded, isA<List>());

      final gotList = decoded as List;
      expect(gotList, hasLength(cards.length));

      for (var i = 0; i < expectedList.length; i++) {
        expect(gotList[i], expectedList[i]);
      }
    });

    test('copies nothing but an empty list when there are no cards', () async {
      // ACT
      await exportCardsToClipboard([]);

      // ASSERT
      expect(clipboard.clipboardText, '[]');
    });
  });
}
