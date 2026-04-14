import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/util/list_notifier.dart';
import 'package:flutter/foundation.dart';

class EditableCardListViewOptions {
  const EditableCardListViewOptions({
    required this.numberOfColumns,
    required this.sortingStyle,
    required this.customOrder,
  });

  factory EditableCardListViewOptions.fromValue(CardListViewOptions value) {
    return EditableCardListViewOptions(
      numberOfColumns: ValueNotifier(value.numberOfColumns),
      sortingStyle: ValueNotifier(value.sortingStyle),
      customOrder: ListNotifier(value.customOrder),
    );
  }

  final ValueNotifier<int> numberOfColumns;
  final ValueNotifier<SortingStyle> sortingStyle;
  final ListNotifier<String> customOrder;

  void loadValue(CardListViewOptions value) {
    numberOfColumns.value = value.numberOfColumns;
    sortingStyle.value = value.sortingStyle;
    customOrder.value = value.customOrder;
  }

  CardListViewOptions seal() {
    return CardListViewOptions(
      numberOfColumns: numberOfColumns.value,
      sortingStyle: sortingStyle.value,
      customOrder: customOrder.value,
    );
  }

  void dispose() {
    numberOfColumns.dispose();
    sortingStyle.dispose();
    customOrder.dispose();
  }
}
