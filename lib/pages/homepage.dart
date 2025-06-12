import 'package:cardabase/pages/news.dart';
import 'package:cardabase/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:cardabase/data/cardabase_db.dart'; //card database
import 'package:cardabase/util/card_tile.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import '../util/vibration_provider.dart';
import 'createcardnew.dart';
import 'editcard.dart';
import 'package:hive/hive.dart';

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
        title: Text('Enter Password', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',) ),
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
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Roboto-Regular.ttf',
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
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
                        content: const Row(
                          children: [
                            Icon(Icons.error, size: 15, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: TextStyle(
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
                style: ElevatedButton.styleFrom(elevation: 0.0),
                child: Text(
                  'DELETE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.tertiary,
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
        title: Text('Enter Password', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',) ),
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
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Roboto-Regular.ttf',
                ),
                prefixIcon: Icon(
                  Icons.password,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                labelText: 'Password',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text == passwordbox.get('PW')) {
                    FocusScope.of(context).unfocus();

                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditCard(
                            cardColorPreview: Color.fromARGB(
                                255, cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4]
                            ),
                            redValue: cdb.myShops[index][2],
                            greenValue: cdb.myShops[index][3],
                            blueValue: cdb.myShops[index][4],
                            hasPassword: (cdb.myShops[index].length > 6 && cdb.myShops[index][6] is bool)
                                ? cdb.myShops[index][6]
                                : false,
                            index: index,
                            cardTextPreview: cdb.myShops[index][0],
                            cardName: cdb.myShops[index][0],
                            cardId: cdb.myShops[index][1],
                            cardType: (cdb.myShops[index].length > 5 && cdb.myShops[index][5] is String)
                                ? cdb.myShops[index][5]
                                : 'CardType.ean13',
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
                        content: const Row(
                          children: [
                            Icon(Icons.error, size: 15, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Incorrect password!',
                              style: TextStyle(
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
                style: ElevatedButton.styleFrom(elevation: 0.0),
                child: Text(
                  'EDIT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto-Regular.ttf',
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.tertiary,
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
    if (cdb.myShops[index][6] == true) {
      if (passwordbox.isNotEmpty) {
        showUnlockDialogDelete(context, index);
      } else {
        deleteCard(index);
      }
    } else {
      deleteCard(index);
    }
  }

  //Deleting a card
  void deleteCard(int index) {
    setState(() {
      cdb.myShops.removeAt(index);
    });
    cdb.updateDataBase();
  }

  void duplicateCard(int index) {
    setState(() {
      cdb.myShops.insert(index + 1,[cdb.myShops[index][0], cdb.myShops[index][1], cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4], cdb.myShops[index][5], cdb.myShops[index][6]]);
    });
    cdb.updateDataBase();
  }

  void editCard(context, int index) {
    if (cdb.myShops[index][6] == true) {
      if (passwordbox.isNotEmpty) {
        showUnlockDialogEdit(context, index);
      } else {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditCard(
              cardColorPreview: Color.fromARGB(
                  255, cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4]
              ),
              redValue: cdb.myShops[index][2],
              greenValue: cdb.myShops[index][3],
              blueValue: cdb.myShops[index][4],
              hasPassword: (cdb.myShops[index].length > 6 && cdb.myShops[index][6] is bool)
                  ? cdb.myShops[index][6]
                  : false,
              index: index,
              cardTextPreview: cdb.myShops[index][0],
              cardName: cdb.myShops[index][0],
              cardId: cdb.myShops[index][1],
              cardType: (cdb.myShops[index].length > 5 && cdb.myShops[index][5] is String)
                  ? cdb.myShops[index][5]
                  : 'CardType.ean13',
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
            cardColorPreview: Color.fromARGB(
                255, cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4]
            ),
            redValue: cdb.myShops[index][2],
            greenValue: cdb.myShops[index][3],
            blueValue: cdb.myShops[index][4],
            hasPassword: (cdb.myShops[index].length > 6 && cdb.myShops[index][6] is bool)
                ? cdb.myShops[index][6]
                : false,
            index: index,
            cardTextPreview: cdb.myShops[index][0],
            cardName: cdb.myShops[index][0],
            cardId: cdb.myShops[index][1],
            cardType: (cdb.myShops[index].length > 5 && cdb.myShops[index][5] is String)
                ? cdb.myShops[index][5]
                : 'CardType.ean13',
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
    if (index + 1 != cdb.myShops.length) {
      setState(() {
        cdb.myShops.insert(index + 2,[cdb.myShops[index][0], cdb.myShops[index][1], cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4], cdb.myShops[index][5], cdb.myShops[index][6]]);
        cdb.myShops.removeAt(index);
        cdb.updateDataBase();
      });
    }
  }

  void columnAmountDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState2) {
            return AlertDialog(
              title: Text('View', style: TextStyle(
                color: Theme.of(context).colorScheme.inverseSurface,
                fontFamily: 'Roboto-Regular.ttf',),),
              content: SizedBox(
                height: 100,
                width: double.maxFinite,
                child: Column(
                  children: <Widget>[
                    Text('Columns: $columnAmount', style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto-Regular.ttf',
                      color: Theme.of(context).colorScheme.tertiary,
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
                            columnAmountDouble = newValue;
                            columnAmount = columnAmountDouble.round().toInt();
                            Hive.box('settingsBox').put('columnAmount', columnAmount); // Save to Hive
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(elevation: 0.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('SELECT', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto-Regular.ttf',
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.tertiary,
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,// - BACKGROUND COLOR (DEFAULT)
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.newspaper, color: Theme.of(context).colorScheme.secondary,), onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsPage()));
        },), //createNewCard
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
        title: TextButton(
          onPressed: columnAmountDialog,
          child: Text(
            'Cardabase',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'xirod',
              letterSpacing: 5,
              color: Theme.of(context).colorScheme.tertiary,
              )
            ),
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
                print(cdb.myShops);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCard()), ).then((value) => setState(() {}));},
              child: const Icon(Icons.add_card),
            ),
          ),
        ),
      ),
      body: cdb.myShops.isEmpty
           ? const Center(
            child: Text(
              'Your Cardabase is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto-Regular.ttf',),
            ),
          )
          : (columnAmount == 1
            ? ListView.builder(
                physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                itemCount: cdb.myShops.length,
                itemBuilder: (context, index) {
                  return CardTile(
                    shopName: cdb.myShops[index][0],
                    deleteFunction: (context) => askForPasswordDelete(index),
                    cardnumber: cdb.myShops[index][1],
                    cardTileColor: Color.fromARGB(
                        255, cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4]
                    ),
                    cardType: (cdb.myShops[index].length > 5 && cdb.myShops[index][5] is String)
                        ? cdb.myShops[index][5]
                        : 'CardType.ean13',
                    hasPassword: (cdb.myShops[index].length > 6 && cdb.myShops[index][6] is bool)
                        ? cdb.myShops[index][6]
                        : false,
                    red: cdb.myShops[index][2],
                    green: cdb.myShops[index][3],
                    blue: cdb.myShops[index][4],
                    duplicateFunction: (context) => duplicateCard(index),
                    editFunction: (context) => editCard(context, index),
                    moveUpFunction: (context) => moveUp(index),
                    moveDownFunction: (context) => moveDown(index),
                    labelSize: 50,
                    borderSize: 15,
                    marginSize: 20,
                  );
                },
              )
            : GridView.builder(
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
                    shopName: cdb.myShops[index][0],
                    deleteFunction: (context) => askForPasswordDelete(index),
                    cardnumber: cdb.myShops[index][1],
                    cardTileColor: Color.fromARGB(
                        255, cdb.myShops[index][2], cdb.myShops[index][3], cdb.myShops[index][4]
                    ),
                    cardType: (cdb.myShops[index].length > 5 && cdb.myShops[index][5] is String)
                        ? cdb.myShops[index][5]
                        : 'CardType.ean13',
                    hasPassword: (cdb.myShops[index].length > 6 && cdb.myShops[index][6] is bool)
                        ? cdb.myShops[index][6]
                        : false,
                    red: cdb.myShops[index][2],
                    green: cdb.myShops[index][3],
                    blue: cdb.myShops[index][4],
                    duplicateFunction: (context) => duplicateCard(index),
                    editFunction: (context) => editCard(context, index),
                    moveUpFunction: (context) => moveUp(index),
                    moveDownFunction: (context) => moveDown(index),
                    labelSize: 50 / columnAmount,
                    borderSize: 15 / columnAmount,
                    marginSize: 20 / (columnAmount / 2),
                  );
                },
              )
          ),
      );
  }
}