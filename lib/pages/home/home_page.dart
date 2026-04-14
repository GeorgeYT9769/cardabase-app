import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/widgets/edit_card_page.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/feature/cards/widgets/card_list.dart';
import 'package:cardabase/feature/settings/get_it.dart';
import 'package:cardabase/feature/settings/model.dart';
import 'package:cardabase/feature/settings/widgets/settings_page.dart';
import 'package:cardabase/pages/home/card_list_view_options_dialog.dart';
import 'package:cardabase/pages/home/password_challenge_dialog.dart';
import 'package:cardabase/pages/welcome_screen.dart';
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
  final _settingsBox = GetIt.I<SettingsBox>();

  final cardsBox = GetIt.I<LoyaltyCardsBox>();
  final passwordBox = Hive.box('password');

  bool isInReorderingMode = false;
  String? tagFilter;

  @override
  void initState() {
    super.initState();
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
        ),
      );
      await _settingsBox.save(editableSettings.seal());
      setState(() {
        this.isInReorderingMode = isInReorderingMode.value;
        this.tagFilter = tagFilter.value;
      });
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
              CardList(
                tagFilter: tagFilter,
                isInReorderingMode: isInReorderingMode,
              ),
            ],
          );
        },
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
