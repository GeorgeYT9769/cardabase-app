import 'package:cardabase/pages/news.dart';
import 'package:cardabase/pages/settings.dart';
import 'package:cardabase/util/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:cardabase/data/cardabase_db.dart'; //card database
import 'package:cardabase/util/card_tile.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import '../util/vibration_provider.dart';
import 'createcardnew.dart';
import 'editcard.dart';
import 'package:hive/hive.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class Homepage extends StatefulWidget {

  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  cardabase_db cdb = cardabase_db();
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

  showUnlockDialogDelete(BuildContext context, int index) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30)),
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
                focusColor: Theme.of(context).colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
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
                            Icon(Icons.error, size: 15, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                child: Text(
                  'DELETE',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  showUnlockDialogEdit(BuildContext context, int index) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30) ),
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
                focusColor: Theme.of(context).colorScheme.primary,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
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
                                255, cdb.myShops[index]['redValue'], cdb.myShops[index]['greenValue'], cdb.myShops[index]['blueValue']
                            ),
                            redValue: cdb.myShops[index]['redValue'] ?? 158,
                            greenValue: cdb.myShops[index]['greenValue'] ?? 158,
                            blueValue: cdb.myShops[index]['blueValue'] ?? 158,
                            hasPassword: cdb.myShops[index]['hasPassword'] ?? false,
                            cardTextPreview: (cdb.myShops[index]['cardName'] ?? '').toString(),
                            cardName: cdb.myShops[index]['cardName'] ?? '',
                            cardId: (cdb.myShops[index]['cardId'] ?? '').toString(),
                            cardType: (cdb.myShops[index]['cardType'] ?? 'CardType.ean13').toString(),
                            tags: cdb.myShops[index]['tags'] ?? [],
                          ),
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
                            Icon(Icons.error, size: 15, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                child: Text(
                  'EDIT',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  askForPasswordDelete(int index) {
    if (cdb.myShops[index]['hasPassword'] == true) {
      if (passwordbox.isNotEmpty) {
        showUnlockDialogDelete(context, index);
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

  void editCard(context, int index) {
    final card = cdb.myShops[index];
    if (cdb.myShops[index]['hasPassword'] == true) {
      if (passwordbox.isNotEmpty) {
        showUnlockDialogEdit(context, index);
      } else {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditCard(
              index: index,
              cardColorPreview: Color.fromARGB(
                  255, card['redValue'], card['greenValue'], card['blueValue']
              ),
              redValue: card['redValue'],
              greenValue: card['greenValue'],
              blueValue: card['blueValue'],
              hasPassword: card['hasPassword'] ?? false,
              cardTextPreview: card['cardName'].toString(),
              cardName: card['cardName'].toString(),
              cardId: (card['cardId'] ?? '').toString(),
              cardType: (card['cardType'] ?? 'CardType.ean13').toString(),
              tags: card['tags'] ?? [],
            ),
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
                255, card['redValue'], card['greenValue'], card['blueValue']
            ),
            redValue: card['redValue'],
            greenValue: card['greenValue'],
            blueValue: card['blueValue'],
            hasPassword: card['hasPassword'] ?? false,
            cardTextPreview: card['cardName'].toString(),
            cardName: card['cardName'].toString(),
            cardId: (card['cardId'] ?? '').toString(),
            cardType: (card['cardType'] ?? 'CardType.ean13').toString(),
            tags: card['tags'] ?? [],
          ),
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


  void columnAmountDialog() async {

    final box = Hive.box('settingsBox');
    final List<dynamic> allTags = box.get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState2) {
            return AlertDialog(
              title: Text('Sort', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.inverseSurface,
                fontSize: 30
              )),
              content: SizedBox(
                height: 400,
                width: double.maxFinite,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                  child: Column(
                    children: <Widget>[
                      Text('Tags:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontWeight: FontWeight.w900
                      )),
                      SizedBox(height: 10,),
                      SingleChildScrollView(
                        physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            allTags.length,
                                (chipIndex) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ActionChip(
                                label: Text(allTags[chipIndex]),
                                onPressed: () async {
                                  setState2 (() {
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
                                labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: selectedTag == allTags[chipIndex]
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.inverseSurface,
                                ),
                                backgroundColor: selectedTag == allTags[chipIndex]
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                side: BorderSide(
                                  color: selectedTag == allTags[chipIndex]
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  width: selectedTag == allTags[chipIndex] ? 2 : 1,
                                ),
                                avatar: selectedTag == allTags[chipIndex]
                                    ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.onPrimary)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Divider(
                        color: Theme.of(context).colorScheme.primary,
                        thickness: 1.0,
                      ),
                      SizedBox(height: 10,),
                      Text('Sort by:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontWeight: FontWeight.w900
                      )),
                      SizedBox(height: 10,),
                      DropdownMenu(
                        dropdownMenuEntries: [
                          DropdownMenuEntry<String>(
                              value: 'nameaz',
                              label: 'Name 0-Z',
                              style: ButtonStyle(
                                  elevation: WidgetStateProperty.all(0.0),
                              )
                          ),
                          DropdownMenuEntry<String>(
                              value: 'nameza',
                              label: 'Name Z-0',
                              style: ButtonStyle(
                                  elevation: WidgetStateProperty.all(0.0),
                              )
                          ),
                          DropdownMenuEntry<String>(
                              value: 'latest',
                              label: 'Latest',
                              style: ButtonStyle(
                                  elevation: WidgetStateProperty.all(0.0),)
                          ),
                          DropdownMenuEntry<String>(
                              value: 'oldest',
                              label: 'Oldest',
                              style: ButtonStyle(
                                  elevation: WidgetStateProperty.all(0.0),
                              )
                          ),
                        ],
                        initialSelection: Hive.box('settingsBox').get('sort', defaultValue: 'nameaz'),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
                          focusColor: Theme.of(context).colorScheme.primary,
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                          labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value == 'nameaz') {
                              cdb.myShops.sort((a, b) => a['cardName'].compareTo(b['cardName']));
                            } else if (value == 'nameza') {
                              cdb.myShops.sort((a, b) => b['cardName'].compareTo(a['cardName']));
                            } else if (value == 'latest') {
                              cdb.myShops.sort((a, b) => b['uniqueId'].compareTo(a['uniqueId']));
                            } else if (value == 'oldest') {
                              cdb.myShops.sort((a, b) => a['uniqueId'].compareTo(b['uniqueId']));
                            }
                            Hive.box('settingsBox').put('sort', value);
                            cdb.updateDataBase();
                          });
                        }
                        ,
                      ),
                      SizedBox(height: 10,),
                      Divider(
                        color: Theme.of(context).colorScheme.primary,
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
                      ),
                      Divider(
                        color: Theme.of(context).colorScheme.primary,
                        thickness: 1.0,
                      ),
                      SizedBox(height: 10,),
                      Text('Columns: $columnAmount', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.inverseSurface,
                      )),
                      SizedBox(height: 10,),
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
                              columnAmount = columnAmountDouble.round().toInt();
                              Hive.box('settingsBox').put('columnAmount', columnAmount);
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
                    style: OutlinedButton.styleFrom(elevation: 0.0, side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('SELECT', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),),
                  ),
                ),
              ],
            );
          }
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
    future: Hive.isBoxOpen('mybox') ? Future.value() : Hive.openBox('mybox'),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Storage error: ${snapshot.error}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildMainContent(context);
    },
  );
}

Widget _buildMainContent(BuildContext context) {
  Widget content;

  try {
    if (cdb.myShops.isEmpty) {
      content = Center(
        child: Text(
          'Your Cardabase is empty',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    } else if (columnAmount == 1) {
      if (reorderMode) {
        content = Column(
          children: [
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = cdb.myShops.removeAt(oldIndex);
                    cdb.myShops.insert(newIndex, item);
                    cdb.updateDataBase();
                  });
                },
                children: List.generate(
                  cdb.myShops.length,
                  (index) => CardTile(
                    key: ValueKey('${cdb.myShops[index]['uniqueId']}'),
                    dragHandle: reorderMode
                        ? ReorderableDragStartListener(
                            index: index,
                            child: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.secondary,),
                          )
                        : null,
                    shopName: (cdb.myShops[index]['cardName'] ?? 'No Name').toString(),
                    deleteFunction: (context) => askForPasswordDelete(index),
                    cardnumber: cdb.myShops[index]['cardId'].toString(),
                    cardTileColor: Color.fromARGB(
                      255,
                      cdb.myShops[index]['redValue'] ?? 158,
                      cdb.myShops[index]['greenValue'] ?? 158,
                      cdb.myShops[index]['blueValue'] ?? 158,
                    ),
                    cardType: cdb.myShops[index]['cardType'] ?? 'CardType.ean13',
                    hasPassword: cdb.myShops[index]['hasPassword'] ?? false,
                    red: cdb.myShops[index]['redValue'] ?? 158,
                    green: cdb.myShops[index]['greenValue'] ?? 158,
                    blue: cdb.myShops[index]['blueValue'] ?? 158,
                    editFunction: (context) => editCard(context, index),
                    moveUpFunction: (context) => moveUp(index),
                    moveDownFunction: (context) => moveDown(index),
                    labelSize: 50,
                    borderSize: 15,
                    marginSize: 20,
                    tags: cdb.myShops[index]['tags'] ?? [],
                    reorderMode: reorderMode,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        content = Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                itemCount: cdb.myShops.length,
                itemBuilder: (context, index) {
                  return CardTile(
                    key: ValueKey('${cdb.myShops[index]['uniqueId']}'),
                    shopName: (cdb.myShops[index]['cardName'] ?? 'No Name').toString(),
                    deleteFunction: (context) => askForPasswordDelete(index),
                    cardnumber: cdb.myShops[index]['cardId'].toString(),
                    cardTileColor: Color.fromARGB(
                      255,
                      cdb.myShops[index]['redValue'] ?? 158,
                      cdb.myShops[index]['greenValue'] ?? 158,
                      cdb.myShops[index]['blueValue'] ?? 158,
                    ),
                    cardType: cdb.myShops[index]['cardType'] ?? 'CardType.ean13',
                    hasPassword: cdb.myShops[index]['hasPassword'] ?? false,
                    red: cdb.myShops[index]['redValue'] ?? 158,
                    green: cdb.myShops[index]['greenValue'] ?? 158,
                    blue: cdb.myShops[index]['blueValue'] ?? 158,
                    editFunction: (context) => editCard(context, index),
                    moveUpFunction: (context) => moveUp(index),
                    moveDownFunction: (context) => moveDown(index),
                    labelSize: 50,
                    borderSize: 15,
                    marginSize: 20,
                    tags: cdb.myShops[index]['tags'] ?? [],
                    reorderMode: reorderMode,
                  );
                },
              ),
            ),
          ],
        );
      }
    } else {
      if (reorderMode) {
        content = Column(
          children: [
            Expanded(
              child: ReorderableGridView.builder(
                physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnAmount,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 1.4,
                ),
                itemCount: cdb.myShops.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final item = cdb.myShops.removeAt(oldIndex);
                    cdb.myShops.insert(newIndex, item);
                    cdb.updateDataBase();
                  });
                },
                itemBuilder: (context, index) {
                  return CardTile(
                    key: ValueKey('${cdb.myShops[index]['uniqueId']}'),
                    shopName: (cdb.myShops[index]['cardName'] ?? 'No Name').toString(),
                    deleteFunction: (context) => askForPasswordDelete(index),
                    cardnumber: cdb.myShops[index]['cardId'].toString(),
                    cardTileColor: Color.fromARGB(
                      255,
                      cdb.myShops[index]['redValue'] ?? 158,
                      cdb.myShops[index]['greenValue'] ?? 158,
                      cdb.myShops[index]['blueValue'] ?? 158,
                    ),
                    cardType: cdb.myShops[index]['cardType'] ?? 'CardType.ean13',
                    hasPassword: cdb.myShops[index]['hasPassword'] ?? false,
                    red: cdb.myShops[index]['redValue'] ?? 158,
                    green: cdb.myShops[index]['greenValue'] ?? 158,
                    blue: cdb.myShops[index]['blueValue'] ?? 158,
                    editFunction: (context) => editCard(context, index),
                    moveUpFunction: (context) => moveUp(index),
                    moveDownFunction: (context) => moveDown(index),
                    labelSize: 50 / columnAmount,
                    borderSize: 15 / columnAmount,
                    marginSize: 20 / (columnAmount / 2),
                    tags: cdb.myShops[index]['tags'] ?? [],
                    reorderMode: reorderMode,
                  );
                },
              ),
            ),
          ],
        );
      } else {
        content = Column(
          children: [
            Expanded(
              child: GridView.builder(
                physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                padding: const EdgeInsets.all(0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnAmount,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 1.4,
                ),
                itemCount: cdb.myShops.length,
                itemBuilder: (context, index) {
                  return CardTile(
                    key: ValueKey('${cdb.myShops[index]['uniqueId']}'),
                    shopName: (cdb.myShops[index]['cardName'] ?? 'No Name').toString(),
                    deleteFunction: (context) => askForPasswordDelete(index),
                    cardnumber: cdb.myShops[index]['cardId'].toString(),
                    cardTileColor: Color.fromARGB(
                      255,
                      cdb.myShops[index]['redValue'] ?? 158,
                      cdb.myShops[index]['greenValue'] ?? 158,
                      cdb.myShops[index]['blueValue'] ?? 158,
                    ),
                    cardType: cdb.myShops[index]['cardType'] ?? 'CardType.ean13',
                    hasPassword: cdb.myShops[index]['hasPassword'] ?? false,
                    red: cdb.myShops[index]['redValue'] ?? 158,
                    green: cdb.myShops[index]['greenValue'] ?? 158,
                    blue: cdb.myShops[index]['blueValue'] ?? 158,
                    editFunction: (context) => editCard(context, index),
                    moveUpFunction: (context) => moveUp(index),
                    moveDownFunction: (context) => moveDown(index),
                    labelSize: 50 / columnAmount,
                    borderSize: 15 / columnAmount,
                    marginSize: 20 / (columnAmount / 2),
                    tags: cdb.myShops[index]['tags'] ?? [],
                    reorderMode: reorderMode,
                  );
                },
              ),
            ),
          ],
        );
      }
    }
  } catch (e, stack) {
    content = Center(
      child: Text(
        'Error: $e',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      leading: IconButton(icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.secondary,), onPressed: columnAmountDialog), //createNewCard
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary,),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Settings()),
            );
            if (result == true && mounted) {
              setState(() {
                cdb.loadData();
              });
            }
          },
        ),
      ],
      title: Text(
        'Cardabase',
        style: Theme.of(context).textTheme.titleLarge?.copyWith()
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Theme.of(context).colorScheme.surface,
    ),
//createNewCard
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
                MaterialPageRoute(builder: (builder) => const CreateCard(), )
              ).then((value) => setState(() {
                cdb.loadData();
              }));},
            child: const Icon(Icons.add_card),
          ),
        ),
      ),
    ),
    body: content,
);
}
}