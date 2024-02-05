import 'package:cardabase/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cardabase/data/cardabase_db.dart'; //card database
import 'package:cardabase/util/card_tile.dart';
import 'package:restart_app/restart_app.dart';
import 'createcardnew.dart';

class Homepage extends StatefulWidget {

  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {

  final _myBox = Hive.box('mybox');
  cardabase_db cdb = cardabase_db();


  @override
  void initState() {
    if (_myBox.get('CARDLIST') == null) {
      cdb.myShops.add(['Default', '4545903166393', 158, 158, 158,]);
    } else {
      cdb.loadData();
    }
    super.initState();
  }


  //Deleting a card
  void deleteCard(int index) {
    setState(() {
      cdb.myShops.removeAt(index);
    });
    cdb.updateDataBase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,// - BACKGROUND COLOR (DEFAULT)
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
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      floatingActionButton: FloatingActionButton( //createNewCard
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCard()), ).then((value) => setState(() {}));},
        child: const Icon(Icons.add_card),
      ),
      body:
          ListView.builder(
            itemCount: cdb.myShops.length,
            itemBuilder: (context, index) {
              return CardTile(
                shopName: cdb.myShops[index][0],
                deleteFunction: (context) => deleteCard(index),
                cardnumber: cdb.myShops[index][1],
                cardTileColor: Color.fromARGB(255, cdb.myShops[index][2] , cdb.myShops[index][3], cdb.myShops[index][4]),//_myColor.get(1)[5]
                iconColor: Color.fromARGB(255, cdb.myShops[index][2] , cdb.myShops[index][3], cdb.myShops[index][4]),
              );
            },
          ),
      );
  }
}
//9940271115298