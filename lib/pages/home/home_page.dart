import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/data/loyalty_card.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/settings_page.dart';
import 'package:cardabase/pages/edit_card/edit_card.dart';
import 'package:cardabase/pages/home/card_list_view_options_dialog.dart';
import 'package:cardabase/pages/home/password_challenge_dialog.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/util/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  final _settingsBox = GetIt.I<SettingsBox>();

  final CardabaseDb cdb = CardabaseDb();
  final passwordBox = Hive.box('password');

  bool isInReorderingMode = false;
  String? tagFilter;

  @override
  void initState() {
    super.initState();
    cdb.loadData();
  }

  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  void saveAndApplySortingStyle() {
    final sortOptions = _settingsBox.value.cardListViewOptions;
    switch (sortOptions.sortingStyle) {
      case SortingStyle.nameAz:
      case SortingStyle.nameZa:
        cdb.myShops.sort((a, b) {
          String nameA = a['cardName'] as String;
          String nameB = b['cardName'] as String;
          if (sortOptions.sortNameIgnoreAccents) {
            nameA = removeDiacritics(nameA);
            nameB = removeDiacritics(nameB);
          }
          if (sortOptions.sortNameCaseInsensitive) {
            nameA = nameA.toLowerCase();
            nameB = nameB.toLowerCase();
          }
          return sortOptions.sortingStyle == SortingStyle.nameAz
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        });
      case SortingStyle.latest:
        cdb.myShops.sort((a, b) {
          return b['uniqueId'].compareTo(a['uniqueId']);
        });
      case SortingStyle.oldest:
        cdb.myShops.sort((a, b) {
          return a['uniqueId'].compareTo(b['uniqueId']);
        });
    }
    cdb.updateDataBase();
    setState(() {});
  }

  Future<void> deleteCard(ThemeData theme, LoyaltyCard card) async {
    if (passwordBox.isNotEmpty && card.requiresAuth) {
      final success = await showDialog<bool>(
        context: context,
        builder: (context) => PasswordChallengeDialog(
          challengeButtonChild: Text(
            'DELETE',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ).then((value) => value ?? false);

      if (!success || !mounted) {
        return;
      }
    }

    cdb.remove(card.uniqueId);
    setState(() {});
  }

  Future<void> addCard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => EditCard(
          card: LoyaltyCard.empty(),
        ),
      ),
    );
    cdb.loadData();
    setState(() {});
  }

  Future<void> editCard(ThemeData theme, LoyaltyCard card) async {
    if (passwordBox.isNotEmpty && card.requiresAuth) {
      final success = await showDialog<bool>(
        context: context,
        builder: (context) => PasswordChallengeDialog(
          challengeButtonChild: Text(
            'EDIT',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ).then((value) => value ?? false);

      if (success != true || !mounted) {
        return;
      }
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCard(card: card)),
    );

    setState(() => cdb.loadData());
  }

  Future<void> showCardListViewOptionsDialog() async {
    final settings = _settingsBox.value;
    final isInReorderingMode = ValueNotifier(this.isInReorderingMode);
    final tagFilter = ValueNotifier(this.tagFilter);
    final editableSettings = settings.editable();

    try {
      await showDialog(
        context: context,
        builder: (context) => CardListViewOptionsDialog(
          allTags: settings.tags,
          isInReorderingMode: isInReorderingMode,
          tagFilter: tagFilter,
          sortingStyle: editableSettings.cardListViewOptions.sortingStyle,
          numberOfColumns: editableSettings.cardListViewOptions.numberOfColumns,
          sortNameCaseInsensitive: editableSettings.cardListViewOptions.sortNameCaseInsensitive,
          sortNameIgnoreAccents: editableSettings.cardListViewOptions.sortNameIgnoreAccents,
        ),
      );
      await _settingsBox.save(editableSettings.seal());
      setState(() {
        this.isInReorderingMode = isInReorderingMode.value;
        this.tagFilter = tagFilter.value;
      });
      saveAndApplySortingStyle();
    } finally {
      isInReorderingMode.dispose();
      tagFilter.dispose();
      editableSettings.dispose();
    }
  }

  Future<void> navigateToWelcomeScreen() {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => const WelcomeScreen(
          currentAppVersion: '1.5.0',
        ),
      ),
    );
  }

  Future<void> navigateToSettingsScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result == true) {
      cdb.loadData();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: _addCardButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ValueListenableBuilder(
        valueListenable: _settingsBox.listenable(),
        builder: (context, settingsBox, _) {
          final settings = settingsBox.value;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            slivers: [
              SliverAppBar(
                leading: IconButton(
                  icon: Icon(Icons.sort, color: theme.colorScheme.secondary),
                  onPressed: showCardListViewOptionsDialog,
                ),
                actions: [
                  if (settings.developerOptions.isEnabled)
                    IconButton(
                      icon: Icon(
                        Icons.web_stories,
                        color: theme.colorScheme.secondary,
                      ),
                      onPressed: navigateToWelcomeScreen,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: theme.colorScheme.secondary,
                    ),
                    onPressed: navigateToSettingsScreen,
                  ),
                ],
                title: Text(
                  'Cardabase',
                  style: theme.textTheme.titleLarge?.copyWith(),
                ),
                centerTitle: true,
                elevation: 0.0,
                backgroundColor: theme.colorScheme.surface,
                floating: true,
                snap: true,
              ),
              _buildContentSliver(context, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContentSliver(BuildContext context, ThemeData theme) {
    if (cdb.myShops.isEmpty) {
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
        _settingsBox.value.cardListViewOptions.numberOfColumns;

    var cards = cdb.getAll();
    if (tagFilter != null) {
      cards = cards.where((card) => card.tags.contains(tagFilter));
    }
    final sliverChildren = cards
        .map((card) => _card(theme, card, numberOfColumns))
        .toList(growable: true);

    if (isInReorderingMode) {
      return SliverPadding(
        padding: const EdgeInsets.all(gridPadding),
        sliver: ReorderableSliverGridView.count(
          crossAxisCount: numberOfColumns,
          childAspectRatio: childAspectRatio,
          children: sliverChildren,
          onReorder: (oldIndex, newIndex) {
            cdb.moveByIndex(oldIndex, newIndex);
            setState(() {});
          },
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.all(gridPadding),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => sliverChildren[index],
            childCount: sliverChildren.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: numberOfColumns,
            childAspectRatio: childAspectRatio,
          ),
        ),
      );
    }
  }

  Widget _card(ThemeData theme, LoyaltyCard card, int numberOfColumns) {
    return CardTile(
      key: ValueKey(card.uniqueId),
      shopName: card.name,
      deleteFunction: (context) => deleteCard(theme, card),
      cardData: card.data,
      cardTileColor: card.color ?? Colors.grey,
      barcodeType: card.barcodeType,
      hasPassword: card.requiresAuth,
      editFunction: (context) => editCard(theme, card),
      moveUpFunction: (context) {
        cdb.move(card.uniqueId, (index) => index - 1);
        setState(() {});
      },
      moveDownFunction: (context) {
        cdb.move(card.uniqueId, (index) => index + 1);
        setState(() {});
      },
      duplicateFunction: (context) {
        cdb.duplicate(card.uniqueId);
        setState(() {});
      },
      labelSize: numberOfColumns == 1 ? 50 : 50 / numberOfColumns,
      borderSize: numberOfColumns == 1 ? 15 : 20 / numberOfColumns,
      marginSize: numberOfColumns == 1 ? 10 : 20 / numberOfColumns,
      tags: card.tags.toList(growable: false),
      reorderMode: isInReorderingMode,
      note: card.notes ?? 'Card notes are displayed here...',
      uniqueId: card.uniqueId,
      frontImagePath: card.frontImagePath ?? '',
      backImagePath: card.backImagePath ?? '',
      useFrontFaceOverlay: card.useFrontFaceOverlay,
      hideTitle: card.hideTitle,
      pointsAmount: card.points,
    );
  }

  Widget _addCardButton() {
    return Bounceable(
      onTap: () {},
      child: SizedBox(
        height: 70,
        width: 70,
        child: FittedBox(
          child: FloatingActionButton(
            elevation: 0.0,
            enableFeedback: true,
            tooltip: 'Add a card',
            onPressed: addCard,
            child: const Icon(Icons.add_card),
          ),
        ),
      ),
    );
  }
}
