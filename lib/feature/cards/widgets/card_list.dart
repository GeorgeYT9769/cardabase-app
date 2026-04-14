import 'dart:async';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_bottom_sheet.dart';
import 'package:cardabase/feature/cards/widgets/card_summary.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class CardList extends StatefulWidget {
  const CardList({
    super.key,
    required this.tagFilter,
    required this.isInReorderingMode,
  });

  final String? tagFilter;
  final bool isInReorderingMode;

  @override
  State<CardList> createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final settingsBox = GetIt.I<SettingsBox>();

  StreamSubscription? _cardsSubscription;
  StreamSubscription? _settingsSubscription;

  late List<LoyaltyCard> cardsToDisplay;

  @override
  void initState() {
    super.initState();
    _cardsSubscription = cardsBox.watch().listen((_) {
      setState(() => cardsToDisplay = listCardsToDisplay());
    });
    _settingsSubscription = settingsBox.watch().listen((_) => setState(() {}));
    cardsToDisplay = listCardsToDisplay();
  }

  @override
  void dispose() {
    _cardsSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  List<LoyaltyCard> listCardsToDisplay() {
    final allCards = cardsBox.values.toList(growable: false);
    settingsBox.value.cardListViewOptions.sortCards(allCards);
    if (widget.tagFilter == null) {
      return allCards;
    }
    return allCards
        .where((card) => card.tags.contains(widget.tagFilter))
        .toList(growable: false);
  }

  void moveCard(int oldIndex, int newIndex) {
    final settings = settingsBox.value.editable();
    settings.cardListViewOptions.customOrder.move(oldIndex, newIndex);
    settingsBox.save(settings.seal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (cardsBox.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Your Cardabase is empty',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    const childAspectRatio = 1.4;
    const gridPadding = 8.0;

    final numberOfColumns =
        settingsBox.value.cardListViewOptions.numberOfColumns;

    final sliverChildren = cardsToDisplay
        .map((card) => _card(theme, card, numberOfColumns))
        .toList(growable: true);

    if (widget.isInReorderingMode) {
      return SliverPadding(
        padding: const EdgeInsets.all(gridPadding),
        sliver: ReorderableSliverGridView.count(
          crossAxisCount: numberOfColumns,
          childAspectRatio: childAspectRatio,
          onReorder: moveCard,
          children: sliverChildren,
        ),
      );
    } else {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsetsGeometry.all(gridPadding),
            child: sliverChildren[index],
          ),
          childCount: sliverChildren.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: numberOfColumns,
          childAspectRatio: childAspectRatio,
        ),
      );
    }
  }

  Widget _card(ThemeData theme, LoyaltyCard card, int numberOfColumns) {
    return GestureDetector(
      onLongPress: widget.isInReorderingMode
          ? null
          : () => showLoyaltyCardBottomSheets(context, card),
      child: CardSummary(
        loyaltyCard: card,
        cornerRadius: numberOfColumns == 1 ? 15 : 20 / numberOfColumns,
        fontSize: numberOfColumns == 1 ? 50 : 50 / numberOfColumns,
      ),
    );
  }
}
