import 'package:hive_flutter/hive_flutter.dart';

class cardabase_db {

  List myShops = [];

  final _myBox = Hive.box('mybox');

  //first time
  void createInitialData() {
      _myBox.add(["Default card", "6820060015240", 158, 158, 158]);
  }

  //load the data
  void loadData() {
    myShops = _myBox.get('CARDLIST');
  }

  //update the data
  void updateDataBase() {
    _myBox.put('CARDLIST', myShops);
  }

}
