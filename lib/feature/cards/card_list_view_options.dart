import 'package:cardabase/data/hive.dart';
import 'package:cardabase/feature/cards/edit/editable_card_list_view_options.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/list_extensions.dart';
import 'package:cardabase/util/string_extensions.dart';
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

  /// [sortNameCaseInsensitive] indicates whether the casing should matter when
  /// sorting the cards.
  @HiveField(2, defaultValue: false)
  final bool sortNameCaseInsensitive;

  /// [sortNameIgnoreAccents] indicates whether accents and other symbols should
  /// be ignored when sorting the cards.
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
    if (cards.length <= 1) {
      return;
    }
    late Comparable Function(LoyaltyCard card) selector;
    late int Function(Comparable a, Comparable b) comparer;
    switch (sortingStyle) {
      case SortingStyle.oldest:
        cards.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
        return;
      case SortingStyle.latest:
        cards.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
        return;
      case SortingStyle.nameAz:
        comparer = (a, b) => a.compareTo(b);
        if (sortNameCaseInsensitive && sortNameIgnoreAccents) {
          selector = (c) => c.name.removeDiacritics().toLowerCase();
        } else if (sortNameCaseInsensitive) {
          selector = (c) => c.name.toLowerCase();
        } else if (sortNameIgnoreAccents) {
          selector = (c) => c.name.removeDiacritics();
        } else {
          cards.sort((a, b) => a.name.compareTo(b.name));
          return;
        }
      case SortingStyle.nameZa:
        comparer = (a, b) => b.compareTo(a);
        if (sortNameCaseInsensitive && sortNameIgnoreAccents) {
          selector = (c) => c.name.removeDiacritics().toLowerCase();
        } else if (sortNameCaseInsensitive) {
          selector = (c) => c.name.toLowerCase();
        } else if (sortNameIgnoreAccents) {
          selector = (c) => c.name.removeDiacritics();
        } else {
          cards.sort((a, b) => b.name.compareTo(a.name));
          return;
        }
        return;
      case SortingStyle.custom:
        if (customOrder.isEmpty) {
          return;
        }
        comparer = (a, b) => b.compareTo(a);
        selector = (c) => customOrder.indexOf(c.id);
    }

    cards.sortMapped(selector, comparer);
    return;
  }
}
