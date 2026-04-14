import 'package:cardabase/data/hive.dart';
import 'package:cardabase/feature/cards/edit/editable_card_list_view_options.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:hive_ce/hive.dart';

part 'card_list_view_options.g.dart';

@HiveType(typeId: HiveTypeIds.sortingStyle)
enum SortingStyle {
  @HiveField(0)
  nameAz,
  @HiveField(1)
  nameZa,
  @HiveField(2)
  latest,
  @HiveField(3)
  oldest,
  @HiveField(4)
  custom,
}

@HiveType(typeId: HiveTypeIds.cardListViewOptions)
class CardListViewOptions {
  const CardListViewOptions({
    required this.numberOfColumns,
    required this.sortingStyle,
    required this.sortNameCaseInsensitive,
    required this.sortNameIgnoreAccents,
    required this.customOrder,
  });

  const CardListViewOptions.defaultValue()
      : this(
          numberOfColumns: 1,
          sortingStyle: SortingStyle.latest,
          sortNameCaseInsensitive: false,
          sortNameIgnoreAccents: false,
          customOrder: const [],
        );

  /// [numberOfColumns] specifies the number of columns which should be used
  /// when displaying the grid of cards.
  @HiveField(0)
  final int numberOfColumns;

  /// [sortingStyle] specifies in which order the cards should be sorted.
  @HiveField(1)
  final SortingStyle sortingStyle;

  @HiveField(2, defaultValue: false)
  final bool sortNameCaseInsensitive;
  @HiveField(3, defaultValue: false)
  final bool sortNameIgnoreAccents;

  /// [customOrder] is an ordered list of the ids of the cards which are
  /// displayed. Cards of which the ids are not in this list, are appended to
  /// the end of the grid according to the [sortingStyle].
  @HiveField(4, defaultValue: <String>[])
  final List<String> customOrder;

  EditableCardListViewOptions editable() {
    return EditableCardListViewOptions.fromValue(this);
  }

  void sortCards(List<LoyaltyCard> cards) {
    switch (sortingStyle) {
      case SortingStyle.oldest:
        cards.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
        return;
      case SortingStyle.latest:
        cards.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
        return;
      case SortingStyle.nameAz:
        cards.sort((a, b) => a.name.compareTo(b.name));
        return;
      case SortingStyle.nameZa:
        cards.sort((a, b) => b.name.compareTo(a.name));
        return;
      case SortingStyle.custom:
        if (customOrder.isEmpty) {
          return;
        }
    }

    // We iterate over the custom order and order the cards according to that.
    // By removing the processed elements from the buffer, we can append all
    // other elements at the end.
    var cardIndex = 0;
    final buffer = cards.cast<LoyaltyCard?>().toList(growable: false);
    for (var i = 0; i < customOrder.length; i++) {
      final buffIndex =
          buffer.indexWhere((c) => c != null && c.id == customOrder[i]);
      if (buffIndex < 0) {
        continue;
      }

      cards[cardIndex] = buffer[buffIndex]!;
      cardIndex++;

      // by setting the value at a given index to null, we do not need to
      // recompute the size of the list.
      buffer[buffIndex] = null;
    }

    // append all cards left in the buffer to the end
    for (final card in buffer) {
      if (card == null) {
        continue;
      }
      cards[cardIndex] = card;
      cardIndex++;
    }
  }
}
