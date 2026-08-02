import 'dart:async';

import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/card_list_view_options.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_list.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/settings_page.dart';
import 'package:cardabase/pages/home/card_list_view_options_dialog.dart';
import 'package:cardabase/pages/home/password_challenge_dialog.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/util/widgets/multi_listenable_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  final settingsBox = GetIt.I<SettingsBox>();
  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final passwordBox = Hive.box('password');

  late final settings = settingsBox.value.editable();

  final isInReorderingMode = ValueNotifier(false);
  final tagFilter = ValueNotifier<String?>(null);
  final searchQuery = ValueNotifier<String>('');
  final isSearchVisible = ValueNotifier<bool>(false);
  final searchController = TextEditingController();

  StreamSubscription? cardsSubscription;
  StreamSubscription? settingsSubscription;

  late List<LoyaltyCard> cardsToDisplay;

  @override
  void initState() {
    super.initState();
    settingsSubscription = settingsBox.watch().listen((_) {
      settings.loadValue(settingsBox.value);
      setState(() {});
    });
    cardsSubscription = cardsBox.watch().listen((_) => setState(() {}));
    cardsToDisplay = listCardsToDisplay();
  }

  @override
  void dispose() {
    cardsSubscription?.cancel();
    settingsSubscription?.cancel();
    searchQuery.dispose();
    isSearchVisible.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<LoyaltyCard> listCardsToDisplay() {
    final allCards = cardsBox.values.toList(growable: false);
    settings.cardListViewOptions.seal().sortCards(allCards);
    final tagFilter = this.tagFilter.value;
    final query = searchQuery.value.trim().toLowerCase();

    return allCards.where((card) {
      final matchesTag = tagFilter == null ||
          isInReorderingMode.value ||
          card.tags.contains(tagFilter);
      final matchesSearch =
          query.isEmpty || card.name.toLowerCase().contains(query);
      return matchesTag && matchesSearch;
    }).toList(growable: false);
  }

  Future<void> addCard() {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => EditCardPage(
          cardId: generateUniqueId(),
        ),
      ),
    );
  }

  Future<void> moveCard(int oldIndex, int newIndex) {
    settings.cardListViewOptions.customOrder.move(oldIndex, newIndex);
    settings.cardListViewOptions.sortingStyle.value = SortingStyle.custom;
    return settingsBox.save(settings.seal());
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
      MaterialPageRoute(builder: (context) => EditCardPage(cardId: card.id)),
    );
  }

  Future<void> showCardListViewOptionsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CardListViewOptionsDialog(
        allTags: settings.tags,
        isInReorderingMode: isInReorderingMode,
        tagFilter: tagFilter,
        sortingStyle: settings.cardListViewOptions.sortingStyle,
        numberOfColumns: settings.cardListViewOptions.numberOfColumns,
        sortNameCaseInsensitive:
            settings.cardListViewOptions.sortNameCaseInsensitive,
        sortNameIgnoreAccents:
            settings.cardListViewOptions.sortNameIgnoreAccents,
      ),
    );
    await settingsBox.save(settings.seal());
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

  Future<void> navigateToSettingsScreen() {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: _addCardButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: MultiListenableBuilder(
        listenables: [
          isInReorderingMode,
          tagFilter,
          settings.cardListViewOptions.sortNameIgnoreAccents,
          settings.cardListViewOptions.sortingStyle,
          settings.cardListViewOptions.sortNameCaseInsensitive,
          settings.cardListViewOptions.numberOfColumns,
          settings.cardListViewOptions.customOrder,
          isSearchVisible,
          searchQuery,
        ],
        builder: (context) => SafeArea(
          child: CustomScrollView(
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
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: navigateToSettingsScreen,
                ),
              ],
              title: TapRegion(
                groupId: 'search_bar',
                child: TextButton(
                  onPressed: () {
                    isSearchVisible.value = !isSearchVisible.value;
                    if (!isSearchVisible.value) {
                      searchQuery.value = '';
                      searchController.clear();
                    }
                  },
                  child: Text(
                    'Cardabase',
                    style: theme.textTheme.titleLarge?.copyWith(),
                  ),
                ),
              ),
              centerTitle: true,
              elevation: 0.0,
              backgroundColor: theme.colorScheme.surface,
              floating: true,
              snap: true,
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isSearchVisible.value
                    ? TapRegion(
                        key: const ValueKey('searchBar'),
                        groupId: 'search_bar',
                        onTapOutside: (event) {
                          if (isSearchVisible.value) {
                            isSearchVisible.value = false;
                            searchQuery.value = '';
                            searchController.clear();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: TextFormField(
                            controller: searchController,
                            onChanged: (value) => searchQuery.value = value,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(width: 2.0),
                              ),
                              focusColor: theme.colorScheme.primary,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              labelStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.inverseSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              hintText: 'Search cards...',
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.tertiary,
                              ),
                              prefixIcon: Icon(Icons.search,
                                  color: theme.colorScheme.primary),
                              suffixIcon: searchQuery.value.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchController.clear();
                                        searchQuery.value = '';
                                      },
                                    )
                                  : null,
                              filled: false,
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('noSearchBar')),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 100),
              sliver: CardList(
                isInReorderingMode: isInReorderingMode.value,
                numberOfColumns:
                    settings.cardListViewOptions.numberOfColumns.value,
                cards: listCardsToDisplay(),
                moveCard: moveCard,
                totalCardsCount: cardsBox.length,
                onCardTap: () {
                  isSearchVisible.value = false;
                  searchQuery.value = '';
                  searchController.clear();
                },
              ),
            ),
          ],
        ),
      ),
    ),
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
