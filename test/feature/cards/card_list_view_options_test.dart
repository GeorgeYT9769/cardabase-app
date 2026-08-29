import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_helpers/fakers/loyalty_card.dart';
import '../../../test_helpers/fakers/settings.dart';

void main() {
  group('CardListViewOptions.sortCards', () {
    List<LoyaltyCard> cardsNamed(List<String> names) {
      return [
        for (final (index, name) in names.indexed)
          faker.loyaltyCards.card().copyWith(
                id: 'card-$index',
                name: name,
                lastModifiedAt: DateTime.utc(2024, 1, 1, 12, index),
              ),
      ];
    }

    List<String> namesOf(List<LoyaltyCard> cards) {
      return cards.map((card) => card.name).toList(growable: false);
    }

    group('by name', () {
      test('sorts from a to z', () {
        final cards = cardsNamed(['Carrefour', 'Aldi', 'Delhaize']);

        faker.settings
            .cardListViewOptions(sortingStyle: SortingStyle.nameAz)
            .sortCards(cards);

        expect(namesOf(cards), ['Aldi', 'Carrefour', 'Delhaize']);
      });

      test('sorts from z to a', () {
        final cards = cardsNamed(['Carrefour', 'Aldi', 'Delhaize']);

        faker.settings
            .cardListViewOptions(sortingStyle: SortingStyle.nameZa)
            .sortCards(cards);

        expect(namesOf(cards), ['Delhaize', 'Carrefour', 'Aldi']);
      });

      test('puts capitals first unless it is told to ignore case', () {
        final cards = cardsNamed(['aldi', 'Zeeman']);

        faker.settings
            .cardListViewOptions(sortingStyle: SortingStyle.nameAz)
            .sortCards(cards);

        expect(
          namesOf(cards),
          ['Zeeman', 'aldi'],
          reason: 'a capital Z sorts before a lowercase a in code units',
        );
      });

      test('ignores case when it is told to', () {
        final cards = cardsNamed(['aldi', 'Zeeman']);

        faker.settings
            .cardListViewOptions(
              sortingStyle: SortingStyle.nameAz,
              sortNameCaseInsensitive: true,
            )
            .sortCards(cards);

        expect(namesOf(cards), ['aldi', 'Zeeman']);
      });

      test('folds accents when it is told to', () {
        final cards = cardsNamed(['Étoile', 'Delhaize', 'Fnac']);

        faker.settings
            .cardListViewOptions(
              sortingStyle: SortingStyle.nameAz,
              sortNameIgnoreAccents: true,
            )
            .sortCards(cards);

        expect(
          namesOf(cards),
          ['Delhaize', 'Étoile', 'Fnac'],
          reason: 'É should sort as an E',
        );
      });

      test('folds accents and case together', () {
        final cards = cardsNamed(['étoile', 'Delhaize', 'Fnac']);

        faker.settings
            .cardListViewOptions(
              sortingStyle: SortingStyle.nameAz,
              sortNameIgnoreAccents: true,
              sortNameCaseInsensitive: true,
            )
            .sortCards(cards);

        expect(namesOf(cards), ['Delhaize', 'étoile', 'Fnac']);
      });
    });

    group('by age', () {
      List<LoyaltyCard> agedCards() {
        return [
          faker.loyaltyCards
              .card()
              .copyWith(name: 'Older', lastModifiedAt: DateTime.utc(2024)),
          faker.loyaltyCards
              .card()
              .copyWith(name: 'Newest', lastModifiedAt: DateTime.utc(2025)),
          faker.loyaltyCards
              .card()
              .copyWith(name: 'Oldest', lastModifiedAt: DateTime.utc(2023)),
        ];
      }

      test('puts the card which changed last first', () {
        final cards = agedCards();

        faker.settings
            .cardListViewOptions(sortingStyle: SortingStyle.latest)
            .sortCards(cards);

        expect(namesOf(cards), ['Newest', 'Older', 'Oldest']);
      });

      test('puts the card which changed first first', () {
        final cards = agedCards();

        faker.settings
            .cardListViewOptions(sortingStyle: SortingStyle.oldest)
            .sortCards(cards);

        expect(namesOf(cards), ['Oldest', 'Older', 'Newest']);
      });
    });

    group('in the order of the user', () {
      test('follows the custom order', () {
        final cards = cardsNamed(['Aldi', 'Delhaize', 'Colruyt']);

        faker.settings.cardListViewOptions(
          sortingStyle: SortingStyle.custom,
          customOrder: ['card-2', 'card-0', 'card-1'],
        ).sortCards(cards);

        expect(namesOf(cards), ['Colruyt', 'Aldi', 'Delhaize']);
      });

      test('puts a card which is not in the order at the end', () {
        final cards = cardsNamed(['Aldi', 'Delhaize', 'Colruyt']);

        faker.settings.cardListViewOptions(
          sortingStyle: SortingStyle.custom,
          customOrder: ['card-2'],
        ).sortCards(cards);

        expect(namesOf(cards).first, 'Colruyt');
        expect(namesOf(cards).skip(1), containsAll(['Aldi', 'Delhaize']));
      });

      test('leaves the cards alone without an order to follow', () {
        final cards = cardsNamed(['Aldi', 'Delhaize', 'Colruyt']);

        faker.settings
            .cardListViewOptions(sortingStyle: SortingStyle.custom)
            .sortCards(cards);

        expect(namesOf(cards), ['Aldi', 'Delhaize', 'Colruyt']);
      });
    });

    test('leaves a list of one or none alone', () {
      final one = cardsNamed(['Aldi']);
      final none = <LoyaltyCard>[];

      faker.settings.cardListViewOptions(sortingStyle: SortingStyle.nameAz)
        ..sortCards(one)
        ..sortCards(none);

      expect(namesOf(one), ['Aldi']);
      expect(none, isEmpty);
    });
  });
}
