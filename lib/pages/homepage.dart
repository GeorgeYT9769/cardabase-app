import 'package:cardabase/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:cardabase/data/cardabase_db.dart'; //card database
import 'package:cardabase/util/card_tile.dart';
import 'createcardnew.dart';
import 'editcard.dart';

class Homepage extends StatefulWidget {

  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  cardabase_db cdb = cardabase_db();

  @override
  void initState() {
    cdb.loadData();
    super.initState();
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
        cdb.loadData(); // Reload data after returning from EditCard
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,// - BACKGROUND COLOR (DEFAULT)
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary,), onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings()));},), //createNewCard
        title: Text(
          'Cardabase',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'xirod',
            letterSpacing: 8,
            color: Theme.of(context).colorScheme.tertiary,
            )
          ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
//createNewCard
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FittedBox(
          child: FloatingActionButton(
            tooltip: 'Add a card',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCard()), ).then((value) => setState(() {}));},
            child: const Icon(Icons.add_card),
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
          : ListView.builder(

            itemCount: cdb.myShops.length,
            itemBuilder: (context, index) {
              return CardTile(
                shopName: cdb.myShops[index][0],
                deleteFunction: (context) => deleteCard(index),
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
              );
            },
          ),
      );
  }
}