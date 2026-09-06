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
import 'package:cardabase/theme/theme.dart';
import 'package:cardabase/util/widgets/blur_wrapper.dart';
import 'package:cardabase/util/widgets/cdb_app_bar_sliver.dart';
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
  final scrollController = ScrollController();

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
    cardsSubscription = cardsBox.watch().listen((_) {
      if (cardsBox.isEmpty) {
        isSearchVisible.value = false;
        searchQuery.value = '';
        searchController.clear();
      }
      setState(() {});
    });
    cardsToDisplay = listCardsToDisplay();
  }

  @override
  void dispose() {
    cardsSubscription?.cancel();
    settingsSubscription?.cancel();
    searchQuery.dispose();
    isSearchVisible.dispose();
    searchController.dispose();
    scrollController.dispose();
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
          challengeButtonChild: const Text('EDIT'),
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
          settings.theme.advancedTextures,
        ],
        builder: (context) => CustomScrollView(
            controller: scrollController,
            physics: cardsBox.isEmpty
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
            slivers: [
            CdbAppBarSliver(
              showBackButton: false,
              leading: cardsBox.isEmpty
                  ? null
                  : TapRegion(
                      groupId: 'search_bar',
                      child: IconButton(
                        icon: Icon(
                          isSearchVisible.value
                              ? Icons.search_off
                              : Icons.search,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: () {
                          isSearchVisible.value = !isSearchVisible.value;
                          if (!isSearchVisible.value) {
                            searchQuery.value = '';
                            searchController.clear();
                          }
                          scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
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
              title: 'Cardabase',
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isSearchVisible.value && cardsBox.isNotEmpty
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
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 10,
                            top: 5,
                            bottom: 5,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: searchController,
                                  onChanged: (value) => searchQuery.value = value,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10,
                                    ),
                                    labelStyle: theme.emphasizedInputLabelStyle,
                                    hintText: 'Search cards...',
                                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.tertiary,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: theme.colorScheme.primary,
                                    ),
                                    suffixIcon: searchQuery.value.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: theme.colorScheme.primary,
                                            ),
                                            onPressed: () {
                                              searchController.clear();
                                              searchQuery.value = '';
                                            },
                                          )
                                        : null,
                                    filled: false,
                                  ),
                                  style: theme.inputTextStyle,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.sort, color: theme.colorScheme.secondary),
                                onPressed: showCardListViewOptionsDialog,
                              ),
                            ],
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
    );
  }

  Widget _addCardButton() {
    final theme = Theme.of(context);
    final advancedTextures = settings.theme.advancedTextures.value;
    return Bounceable(
      onTap: () {},
      child: SizedBox(
        height: 70,
        width: 70,
        child: BlurWrapper(
          useBlur: advancedTextures,
          isCircle: false,
          borderRadius: BorderRadius.circular(20),
          blurSigma: 10,
          child: FittedBox(
            child: FloatingActionButton(
              elevation: 0.0,
              enableFeedback: true,
              tooltip: 'Add a card',
              onPressed: addCard,
              backgroundColor: advancedTextures
                  ? theme.colorScheme.primaryContainer.withValues(alpha: .9)
                  : null,
              child: const Icon(Icons.add_card),
            ),
          ),
        ),
      ),
    );
  }
}
