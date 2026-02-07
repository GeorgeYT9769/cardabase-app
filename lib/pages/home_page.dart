import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/pages/create_card_new.dart';
import 'package:cardabase/pages/edit_card.dart';
import 'package:cardabase/pages/settings.dart';
import 'package:cardabase/pages/welcome_screen.dart';
import 'package:cardabase/util/card_tile.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:cardabase/util/vibration_provider.dart';
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
  CardabaseDb cdb = CardabaseDb();
  final passwordbox = Hive.box('password');
  int columnAmount = 1;
  double columnAmountDouble = 1.0;
  bool reorderMode = false;
  String? selectedTag;

  @override
  void initState() {
    super.initState();
    cdb.loadData();
    columnAmount = Hive.box('settingsBox').get('columnAmount', defaultValue: 1);
    columnAmountDouble = columnAmount.toDouble();
  }

  showUnlockDialogDelete(BuildContext context, ThemeData theme, int index) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password',
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.inverseSurface, fontSize: 30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              obscureText: true,
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
                  color: theme.colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: theme.colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(context).unfocus();

                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);
                      deleteCard(index);
                    });
                  } else {
                    VibrationProvider.vibrateSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: Row(
                          children: [
                            const Icon(Icons.error,
                                size: 15, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 3000),
                        padding: const EdgeInsets.all(5.0),
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        behavior: SnackBarBehavior.floating,
                        dismissDirection: DismissDirection.vertical,
                        backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                    elevation: 0.0,
                    side: BorderSide(
                        color: theme.colorScheme.primary, width: 2.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11))),
                child: Text(
                  'DELETE',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  showUnlockDialogEdit(BuildContext context, ThemeData theme, int index) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password',
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.inverseSurface, fontSize: 30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              obscureText: true,
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
                  color: theme.colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: theme.colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(context).unfocus();

                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditCard(
                              index: index,
                              cardColorPreview: Color.fromARGB(
                                  255,
                                  cdb.myShops[index]['redValue'],
                                  cdb.myShops[index]['greenValue'],
                                  cdb.myShops[index]['blueValue']),
                              redValue: cdb.myShops[index]['redValue'] ?? 158,
                              greenValue:
                                  cdb.myShops[index]['greenValue'] ?? 158,
                              blueValue: cdb.myShops[index]['blueValue'] ?? 158,
                              hasPassword:
                                  cdb.myShops[index]['hasPassword'] ?? false,
                              cardTextPreview:
                                  (cdb.myShops[index]['cardName'] ?? '')
                                      .toString(),
                              cardName: cdb.myShops[index]['cardName'] ?? '',
                              cardId: (cdb.myShops[index]['cardId'] ?? '')
                                  .toString(),
                              cardType: (cdb.myShops[index]['cardType'] ??
                                      'CardType.ean13')
                                  .toString(),
                              tags: cdb.myShops[index]['tags'] ?? [],
                              notes: cdb.myShops[index]['note'] ??
                                  'Card notes are displayed here...',
                              frontFacePath:
                                  cdb.myShops[index]['imagePathFront'] ?? '',
                              backFacePath:
                                  cdb.myShops[index]['imagePathBack'] ?? '',
                              useFrontFaceOverlay:
                                  cdb.myShops[index]['useFrontFaceOverlay'] ?? false,
                              hideTitle: cdb.myShops[index]['hideTitle'] ?? false),
                        ),
                      ).then((value) {
                        setState(() {
                          cdb.loadData();
                        });
                      });
                    });
                  } else {
                    VibrationProvider.vibrateSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: Row(
                          children: [
                            const Icon(Icons.error,
                                size: 15, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 3000),
                        padding: const EdgeInsets.all(5.0),
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        behavior: SnackBarBehavior.floating,
                        dismissDirection: DismissDirection.vertical,
                        backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                    elevation: 0.0,
                    side: BorderSide(
                        color: theme.colorScheme.primary, width: 2.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11))),
                child: Text(
                  'EDIT',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  askForPasswordDelete(ThemeData theme, int index) {
    if (cdb.myShops[index]['hasPassword'] == true) {
      if (passwordbox.isNotEmpty) {
        showUnlockDialogDelete(context, theme, index);
      } else {
        deleteCard(index);
      }
    } else {
      deleteCard(index);
    }
  }

  void toggleReorderMode() {
    setState(() {
      reorderMode = !reorderMode;
    });
  }

  void deleteCard(int index) {
    setState(() {
      cdb.myShops.removeAt(index);
    });
    cdb.updateDataBase();
  }

  void duplicateCard(int index) {
    setState(() {
      cdb.myShops.insert(index + 1, cdb.myShops[index]);
    });
  }

  void editCard(context, ThemeData theme, int index) {
    final card = cdb.myShops[index];
    if (cdb.myShops[index]['hasPassword'] == true) {
      if (passwordbox.isNotEmpty) {
        showUnlockDialogEdit(context, theme, index);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditCard(
                index: index,
                cardColorPreview: Color.fromARGB(255, card['redValue'],
                    card['greenValue'], card['blueValue']),
                redValue: card['redValue'],
                greenValue: card['greenValue'],
                blueValue: card['blueValue'],
                hasPassword: card['hasPassword'] ?? false,
                cardTextPreview: card['cardName'].toString(),
                cardName: card['cardName'].toString(),
                cardId: (card['cardId'] ?? '').toString(),
                cardType: (card['cardType'] ?? 'CardType.ean13').toString(),
                tags: card['tags'] ?? [],
                notes: card['note'] ?? 'Card notes are displayed here...',
                frontFacePath: cdb.myShops[index]['imagePathFront'] ?? '',
                backFacePath: cdb.myShops[index]['imagePathBack'] ?? '',
                useFrontFaceOverlay:
                    cdb.myShops[index]['useFrontFaceOverlay'] ?? false,
                hideTitle: cdb.myShops[index]['hideTitle'] ?? false),
          ),
        ).then((value) {
          setState(() {
            cdb.loadData();
          });
        });
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditCard(
              index: index,
              cardColorPreview: Color.fromARGB(
                  255, card['redValue'], card['greenValue'], card['blueValue']),
              redValue: card['redValue'],
              greenValue: card['greenValue'],
              blueValue: card['blueValue'],
              hasPassword: card['hasPassword'] ?? false,
              cardTextPreview: card['cardName'].toString(),
              cardName: card['cardName'].toString(),
              cardId: (card['cardId'] ?? '').toString(),
              cardType: (card['cardType'] ?? 'CardType.ean13').toString(),
              tags: card['tags'] ?? [],
              notes: card['note'] ?? 'Card notes are displayed here...',
              frontFacePath: cdb.myShops[index]['imagePathFront'] ?? '',
              backFacePath: cdb.myShops[index]['imagePathBack'] ?? '',
              useFrontFaceOverlay:
                  cdb.myShops[index]['useFrontFaceOverlay'] ?? false,
              hideTitle: cdb.myShops[index]['hideTitle'] ?? false),
        ),
      ).then((value) {
        setState(() {
          cdb.loadData();
        });
      });
    }
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

  Future<void> columnAmountDialog(ThemeData theme) async {
    final box = Hive.box('settingsBox');
    final List<dynamic> allTags =
        box.get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState2) {
            return AlertDialog(
              title: Text('Sort',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.inverseSurface, fontSize: 30)),
              content: SizedBox(
                height: 400,
                width: double.maxFinite,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.fast),
                  child: Column(
                    children: <Widget>[
                      Text('Tags:',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 17,
                              color: theme.colorScheme.inverseSurface,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(
                        height: 10,
                      ),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                            decelerationRate: ScrollDecelerationRate.fast),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            allTags.length,
                            (chipIndex) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ActionChip(
                                label: Text(allTags[chipIndex]),
                                onPressed: () {
                                  setState2(() {
                                    setState(() {
                                      final tag = allTags[chipIndex];
                                      if (selectedTag == tag) {
                                        selectedTag = null;
                                        cdb.loadData();
                                      } else {
                                        selectedTag = tag;
                                        cdb.loadData();
                                        cdb.myShops = cdb.myShops.where((shop) {
                                          final tags = shop['tags'];
                                          if (tags is List) {
                                            return tags.contains(tag);
                                          }
                                          return false;
                                        }).toList();
                                      }
                                    });
                                  });
                                },
                                labelStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: selectedTag == allTags[chipIndex]
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.inverseSurface,
                                ),
                                backgroundColor:
                                    selectedTag == allTags[chipIndex]
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onInverseSurface,
                                elevation: selectedTag == allTags[chipIndex]
                                    ? null
                                    : 0.0,
                                side: BorderSide(
                                  color: selectedTag == allTags[chipIndex]
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                  width:
                                      selectedTag == allTags[chipIndex] ? 2 : 1,
                                ),
                                avatar: selectedTag == allTags[chipIndex]
                                    ? Icon(Icons.check,
                                        size: 18,
                                        color: theme.colorScheme.onPrimary)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Divider(
                        color: theme.colorScheme.primary,
                        thickness: 1.0,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text('Sort by:',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 17,
                              color: theme.colorScheme.inverseSurface,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(
                        height: 10,
                      ),
                      DropdownMenu(
                        dropdownMenuEntries: [
                          DropdownMenuEntry<String>(
                              value: 'nameaz',
                              label: 'Name 0-Z',
                              style: ButtonStyle(
                                elevation: WidgetStateProperty.all(0.0),
                              )),
                          DropdownMenuEntry<String>(
                              value: 'nameza',
                              label: 'Name Z-0',
                              style: ButtonStyle(
                                elevation: WidgetStateProperty.all(0.0),
                              )),
                          DropdownMenuEntry<String>(
                              value: 'latest',
                              label: 'Latest',
                              style: ButtonStyle(
                                elevation: WidgetStateProperty.all(0.0),
                              )),
                          DropdownMenuEntry<String>(
                              value: 'oldest',
                              label: 'Oldest',
                              style: ButtonStyle(
                                elevation: WidgetStateProperty.all(0.0),
                              )),
                        ],
                        initialSelection: Hive.box('settingsBox')
                            .get('sort', defaultValue: 'oldest'),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(width: 2.0)),
                          focusColor: theme.colorScheme.primary,
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                              borderRadius: BorderRadius.circular(10)),
                          labelStyle: theme.textTheme.bodyLarge
                              ?.copyWith(color: theme.colorScheme.secondary),
                          iconColor: theme.colorScheme.primary,
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value == 'nameaz') {
                              cdb.myShops.sort((a, b) =>
                                  a['cardName'].compareTo(b['cardName']));
                            } else if (value == 'nameza') {
                              cdb.myShops.sort((a, b) =>
                                  b['cardName'].compareTo(a['cardName']));
                            } else if (value == 'latest') {
                              cdb.myShops.sort((a, b) =>
                                  b['uniqueId'].compareTo(a['uniqueId']));
                            } else if (value == 'oldest') {
                              cdb.myShops.sort((a, b) =>
                                  a['uniqueId'].compareTo(b['uniqueId']));
                            }
                            Hive.box('settingsBox').put('sort', value);
                            cdb.updateDataBase();
                          });
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: theme.colorScheme.primary,
                        thickness: 1.0,
                      ),
                      MySetting(
                        aboutSettingHeader: 'Reorder Cards',
                        settingAction: () {
                          setState2(() {
                            VibrationProvider.vibrateSuccess();
                            toggleReorderMode();
                          });
                        },
                        settingHeader: 'Reorder',
                        settingIcon: Icons.reorder,
                        iconColor: reorderMode ? Colors.green : Colors.red,
                        borderColor: theme.colorScheme.primary,
                      ),
                      Divider(
                        color: theme.colorScheme.primary,
                        thickness: 1.0,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text('Columns: $columnAmount',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.inverseSurface,
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Slider(
                        year2023: false,
                        value: columnAmountDouble,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (double newValue) {
                          setState2(() {
                            setState(() {
                              VibrationProvider.vibrateSuccess();
                              columnAmountDouble = newValue;
                              columnAmount = columnAmountDouble.round();
                              Hive.box('settingsBox')
                                  .put('columnAmount', columnAmount);
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        elevation: 0.0,
                        side: BorderSide(
                            color: theme.colorScheme.primary, width: 2.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11))),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'SELECT',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.inverseSurface,
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: Hive.isBoxOpen('mybox') ? Future.value() : Hive.openBox('mybox'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Storage error: ${snapshot.error}',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          floatingActionButton: Bounceable(
            onTap: () {},
            child: SizedBox(
              height: 70,
              width: 70,
              child: FittedBox(
                child: FloatingActionButton(
                  elevation: 0.0,
                  enableFeedback: true,
                  tooltip: 'Add a card',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (builder) => const CreateCard(),
                        )).then((value) => setState(() {
                          cdb.loadData();
                        }));
                  },
                  child: const Icon(Icons.add_card),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast),
            slivers: [
              SliverAppBar(
                leading: IconButton(
                  icon: Icon(
                    Icons.sort,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: () => columnAmountDialog(theme),
                ),
                actions: [
                  ValueListenableBuilder(
                    valueListenable: Hive.box('settingsBox').listenable(),
                    builder: (context, settingsBox, child) {
                      final bool showLegacyCardButton = settingsBox
                          .get('developerOptions', defaultValue: false);
                      return showLegacyCardButton
                          ? IconButton(
                              icon: Icon(
                                Icons.web_stories,
                                color: theme.colorScheme.secondary,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => const WelcomeScreen(
                                          currentAppVersion: "1.5.0"),
                                    ));
                              })
                          : const SizedBox.shrink();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: theme.colorScheme.secondary,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Settings()),
                      );
                      if (result == true && mounted) {
                        setState(() {
                          cdb.loadData();
                        });
                      }
                    },
                  ),
                ],
                title: Text('Cardabase',
                    style: theme.textTheme.titleLarge?.copyWith()),
                centerTitle: true,
                elevation: 0.0,
                backgroundColor: theme.colorScheme.surface,
                floating: true,
                snap: true,
              ),
              _buildContentSliver(context, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentSliver(BuildContext context, ThemeData theme) {
    try {
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
      final int itemCount = cdb.myShops.length;
      final int crossAxisCount = columnAmount;
      const double childAspectRatio = 1.4;
      const double gridPadding = 8.0;
      if (reorderMode) {
        final List<Widget> children = List.generate(itemCount, (index) {
          if (index >= cdb.myShops.length) return const SizedBox.shrink();
          final card = cdb.myShops[index];
          return CardTile(
            key: ValueKey(card['uniqueId'] ?? index),
            shopName: (card['cardName'] ?? 'No Name').toString(),
            deleteFunction: (context) => askForPasswordDelete(theme, index),
            cardnumber: card['cardId']?.toString() ?? '',
            cardTileColor: Color.fromARGB(
              255,
              card['redValue'] ?? 158,
              card['greenValue'] ?? 158,
              card['blueValue'] ?? 158,
            ),
            cardType: card['cardType'] ?? 'CardType.ean13',
            hasPassword: card['hasPassword'] ?? false,
            red: card['redValue'] ?? 158,
            green: card['greenValue'] ?? 158,
            blue: card['blueValue'] ?? 158,
            editFunction: (context) => editCard(context, theme, index),
            moveUpFunction: (context) => moveUp(index),
            moveDownFunction: (context) => moveDown(index),
            duplicateFunction: (context) => duplicateCard(index),
            labelSize: columnAmount == 1 ? 50 : 50 / columnAmount,
            borderSize: columnAmount == 1 ? 15 : 20 / columnAmount,
            marginSize: columnAmount == 1 ? 10 : 20 / columnAmount,
            tags: card['tags'] ?? [],
            reorderMode: reorderMode,
            note: card['note'] ?? 'Card notes are displayed here...',
            uniqueId: card['uniqueId'] ?? 'Error',
            imagePathFront: card['imagePathFront'] ?? '',
            imagePathBack: card['imagePathBack'] ?? '',
            useFrontFaceOverlay: card['useFrontFaceOverlay'] ?? false,
            hideTitle: card['hideTitle'] ?? false,
          );
        });
        return SliverPadding(
          padding: const EdgeInsets.all(gridPadding),
          sliver: ReorderableSliverGridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            children: children,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final item = cdb.myShops.removeAt(oldIndex);
                cdb.myShops.insert(newIndex, item);
                cdb.updateDataBase();
              });
            },
          ),
        );
      } else {
        return SliverPadding(
          padding: const EdgeInsets.all(gridPadding),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= cdb.myShops.length) return null;
                final card = cdb.myShops[index];
                return CardTile(
                  key: ValueKey(card['uniqueId'] ?? index),
                  shopName: (card['cardName'] ?? 'No Name').toString(),
                  deleteFunction: (context) {
                    return askForPasswordDelete(
                      theme,
                      index,
                    );
                  },
                  cardnumber: card['cardId']?.toString() ?? '',
                  cardTileColor: Color.fromARGB(
                    255,
                    card['redValue'] ?? 158,
                    card['greenValue'] ?? 158,
                    card['blueValue'] ?? 158,
                  ),
                  cardType: card['cardType'] ?? 'CardType.ean13',
                  hasPassword: card['hasPassword'] ?? false,
                  red: card['redValue'] ?? 158,
                  green: card['greenValue'] ?? 158,
                  blue: card['blueValue'] ?? 158,
                  editFunction: (context) => editCard(context, theme, index),
                  moveUpFunction: (context) => moveUp(index),
                  moveDownFunction: (context) => moveDown(index),
                  duplicateFunction: (context) => duplicateCard(index),
                  labelSize: columnAmount == 1 ? 50 : 50 / columnAmount,
                  borderSize: columnAmount == 1 ? 15 : 20 / columnAmount,
                  marginSize: columnAmount == 1 ? 10 : 20 / columnAmount,
                  tags: card['tags'] ?? [],
                  reorderMode: reorderMode,
                  note: card['note'] ?? 'Card notes are displayed here...',
                  uniqueId: card['uniqueId'] ?? 'Error',
                  imagePathFront: card['imagePathFront'] ?? '',
                  imagePathBack: card['imagePathBack'] ?? '',
                  useFrontFaceOverlay: card['useFrontFaceOverlay'] ?? false,
                  hideTitle: card['hideTitle'] ?? false,
                );
              },
              childCount: itemCount,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
            ),
          ),
        );
      }
    } catch (e) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Error: $e',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}
