import 'package:hive_flutter/hive_flutter.dart';

class cardabase_db {

  List myShops = [];

  final _myBox = Hive.box('mybox');

  //load the data
  void loadData() {
    if (_myBox.get('CARDLIST') == null) {
      _myBox.put('CARDLIST', []);
    }
    myShops = _myBox.get('CARDLIST');
  }

  //update the data
  void updateDataBase() {
    _myBox.put('CARDLIST', myShops);
  }

}
