import 'package:hive_flutter/hive_flutter.dart';

class cardabase_db {

  List myShops = [];

  final _myBox = Hive.box('mybox');

  //load the data
  void loadData() {
    final data = _myBox.get('CARDLIST');
    if (data == null) {
      _myBox.put('CARDLIST', []);
      myShops = [];
    } else if (data is List) {
      myShops = data;
    } else if (data is Map) {
      // If old data was a Map, convert to a List of one map
      myShops = [Map<String, dynamic>.from(data)];
      _myBox.put('CARDLIST', myShops);
    } else {
      // Fallback: reset to empty list
      myShops = [];
      _myBox.put('CARDLIST', []);
    }
    //myShops = _myBox.get('CARDLIST');
  }

  //update the data
  void updateDataBase() {
    _myBox.put('CARDLIST', myShops);
  }

  void sortType() {
    myShops.sort((a, b) => a['cardType'].compareTo(b['cardType']));
  }

}
