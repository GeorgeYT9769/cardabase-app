import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/util/list_notifier.dart';
import 'package:flutter/foundation.dart';

class EditableCardListViewOptions {
  const EditableCardListViewOptions({
    required this.numberOfColumns,
    required this.sortingStyle,
    required this.customOrder,
    required this.sortNameCaseInsensitive,
    required this.sortNameIgnoreAccents,
  });

  factory EditableCardListViewOptions.fromValue(CardListViewOptions value) {
    return EditableCardListViewOptions(
      numberOfColumns: ValueNotifier(value.numberOfColumns),
      sortingStyle: ValueNotifier(value.sortingStyle),
      customOrder: ListNotifier(value.customOrder),
      sortNameCaseInsensitive: ValueNotifier(value.sortNameCaseInsensitive),
      sortNameIgnoreAccents: ValueNotifier(value.sortNameIgnoreAccents),
    );
  }

  final ValueNotifier<int> numberOfColumns;
  final ValueNotifier<SortingStyle> sortingStyle;
  final ListNotifier<String> customOrder;
  final ValueNotifier<bool> sortNameCaseInsensitive;
  final ValueNotifier<bool> sortNameIgnoreAccents;

  void loadValue(CardListViewOptions value) {
    numberOfColumns.value = value.numberOfColumns;
    sortingStyle.value = value.sortingStyle;
    customOrder.value = value.customOrder;
    sortNameCaseInsensitive.value = value.sortNameCaseInsensitive;
    sortNameIgnoreAccents.value = value.sortNameIgnoreAccents;
  }

  CardListViewOptions seal() {
    return CardListViewOptions(
      numberOfColumns: numberOfColumns.value,
      sortingStyle: sortingStyle.value,
      customOrder: customOrder.value,
      sortNameCaseInsensitive: sortNameCaseInsensitive.value,
      sortNameIgnoreAccents: sortNameIgnoreAccents.value,
    );
  }

  void dispose() {
    numberOfColumns.dispose();
    sortingStyle.dispose();
    customOrder.dispose();
    sortNameCaseInsensitive.dispose();
    sortNameIgnoreAccents.dispose();
  }
}
