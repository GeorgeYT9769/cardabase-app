import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/data/loyalty_card.dart';
import 'package:cardabase/pages/edit_card/edit_card.dart';
import 'package:cardabase/pages/home/card_list_view_options_dialog.dart';
import 'package:cardabase/pages/home/form_fields/sorting_style_selector.dart';
import 'package:cardabase/pages/home/password_challenge_dialog.dart';
import 'package:cardabase/pages/settings.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/util/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  final CardabaseDb cdb = CardabaseDb();
  final passwordBox = Hive.box('password');
  final settingsBox = Hive.box('settingsBox');

  final isInReorderingMode = ValueNotifier<bool>(false);
  final tagFilter = ValueNotifier<String?>(null);
  final numberOfColumns = ValueNotifier<int>(1);
  final sortingStyle = ValueNotifier<SortingStyle>(SortingStyle.oldest);

  @override
  void initState() {
    super.initState();
    loadSettings();
    cdb.loadData();
    tagFilter.addListener(applyTagFilter);
    numberOfColumns.addListener(saveAndApplyNumberOfColumns);
    sortingStyle.addListener(saveAndApplySortingStyle);
  }

  void loadSettings() {
    numberOfColumns.value =
        settingsBox.get('columnAmount', defaultValue: 1) as int;

    final storedSortingStyle = settingsBox.get('sort');
    if (storedSortingStyle is String) {
      sortingStyle.value = SortingStyle.values.firstWhere(
        (value) => value.toString().toLowerCase() == storedSortingStyle,
        orElse: () => SortingStyle.oldest,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    isInReorderingMode.dispose();
    tagFilter.dispose();
    numberOfColumns.dispose();
    sortingStyle.dispose();
  }

  void applyTagFilter() {
    cdb.myShops = cdb.myShops.where((shop) {
      final tags = shop['tags'];
      if (tags is List) {
        return tags.contains(tagFilter.value);
      }
      return false;
    }).toList();
    setState(() {});
  }

  void saveAndApplyNumberOfColumns() {
    settingsBox.put('columnAmount', numberOfColumns.value);
    setState(() {});
  }

  void saveAndApplySortingStyle() {
    final value = sortingStyle.value;
    switch (sortingStyle.value) {
      case SortingStyle.nameAz:
        cdb.myShops.sort((a, b) {
          return a['cardName'].compareTo(b['cardName']);
        });
      case SortingStyle.nameZa:
        cdb.myShops.sort((a, b) {
          return b['cardName'].compareTo(a['cardName']);
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
    settingsBox.put('sort', value.toString().toLowerCase());
    cdb.updateDataBase();
    setState(() {});
  }

  Future<void> deleteCard(ThemeData theme, int index) async {
    if (passwordBox.isNotEmpty && cdb.getAt(index).requiresAuth) {
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

    setState(() => cdb.myShops.removeAt(index));
    cdb.updateDataBase();
  }

  void duplicateCard(int index) {
    setState(() => cdb.myShops.insert(index + 1, cdb.myShops[index]));
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

  Future<void> editCard(ThemeData theme, int index) async {
    final card = cdb.getAt(index);
    if (passwordBox.isNotEmpty && card.requiresAuth) {
      final success = await showDialog(
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

      if (!success || !mounted) {
        return;
      }
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCard(
          cardIndexInDb: index,
          card: cdb.getAt(index),
        ),
      ),
    );

    setState(() => cdb.loadData());
  }

  void moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = cdb.myShops.removeAt(index);
        cdb.myShops.insert(index - 1, item);
        cdb.updateDataBase();
      });
    }
  }

  void moveDown(int index) {
    if (index + 1 < cdb.myShops.length) {
      setState(() {
        final item = cdb.myShops.removeAt(index);
        cdb.myShops.insert(index + 1, item);
        cdb.updateDataBase();
      });
    }
  }

  Future<void> showCardListViewOptionsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CardListViewOptionsDialog(
        allTags:
            settingsBox.get('tags', defaultValue: <String>[]) as List<String>,
        isInReorderingMode: isInReorderingMode,
        tagFilter: tagFilter,
        sortingStyle: sortingStyle,
        numberOfColumns: numberOfColumns,
      ),
    );
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
        builder: (context) => const Settings(),
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
        valueListenable: settingsBox.listenable(),
        builder: (context, box, child) {
          final showLegacyCardButton =
              settingsBox.get('developerOptions', defaultValue: false) as bool;
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
                  if (showLegacyCardButton)
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
              ValueListenableBuilder(
                valueListenable: isInReorderingMode,
                builder: (context, value, __) => _buildContentSliver(
                  context,
                  theme,
                ),
              ),
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

    final loyaltyCards = cdb.getAll().toList(growable: true);
    final sliverChildren = List.generate(loyaltyCards.length, (index) {
      final card = loyaltyCards[index];
      return CardTile(
        key: ValueKey(card.uniqueId),
        shopName: card.name,
        deleteFunction: (context) => deleteCard(theme, index),
        cardData: card.data,
        cardTileColor: card.color ?? Colors.grey,
        barcodeType: card.barcodeType,
        hasPassword: card.requiresAuth,
        editFunction: (context) => editCard(theme, index),
        moveUpFunction: (context) => moveUp(index),
        moveDownFunction: (context) => moveDown(index),
        duplicateFunction: (context) => duplicateCard(index),
        labelSize: numberOfColumns.value == 1 ? 50 : 50 / numberOfColumns.value,
        borderSize:
            numberOfColumns.value == 1 ? 15 : 20 / numberOfColumns.value,
        marginSize:
            numberOfColumns.value == 1 ? 10 : 20 / numberOfColumns.value,
        tags: card.tags.toList(growable: false),
        reorderMode: isInReorderingMode.value,
        note: card.notes ?? 'Card notes are displayed here...',
        uniqueId: card.uniqueId,
        frontImagePath: card.frontImagePath ?? '',
        backImagePath: card.backImagePath ?? '',
        useFrontFaceOverlay: card.useFrontFaceOverlay,
        hideTitle: card.hideTitle,
        pointsAmount: card.points,
      );
    });

    if (isInReorderingMode.value) {
      return SliverPadding(
        padding: const EdgeInsets.all(gridPadding),
        sliver: ReorderableSliverGridView.count(
          crossAxisCount: numberOfColumns.value,
          childAspectRatio: childAspectRatio,
          children: sliverChildren,
          onReorder: (oldIndex, newIndex) {
            final item = cdb.myShops.removeAt(oldIndex);
            cdb.myShops.insert(newIndex, item);
            cdb.updateDataBase();
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
            crossAxisCount: numberOfColumns.value,
            childAspectRatio: childAspectRatio,
          ),
        ),
      );
    }
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
