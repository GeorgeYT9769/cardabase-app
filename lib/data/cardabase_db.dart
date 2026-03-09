import 'package:cardabase/data/loyalty_card.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class CardabaseDb {
  List myShops = [];

  final _myBox = Hive.box('mybox');

  LoyaltyCard getAt(int index) => _mapEntryToModel(myShops[index]);

  Iterable<LoyaltyCard> getAll() {
    return myShops.map(_mapEntryToModel);
  }

  LoyaltyCard _mapEntryToModel(dynamic entry) {
    final dbMap =
        (entry as Map).map((key, value) => MapEntry(key as String, value));
    return LoyaltyCard.fromDbModel(dbMap);
  }

  //load the data
  void loadData() {
    final data = _myBox.get('CARDLIST');
    if (data == null) {
      _myBox.put('CARDLIST', []);
      myShops = [];
    } else if (data is List) {
      myShops = data;
    } else if (data is Map) {
      myShops = [Map<String, dynamic>.from(data)];
      _myBox.put('CARDLIST', myShops);
    } else {
      myShops = [];
      _myBox.put('CARDLIST', []);
    }
  }

  //update the data
  void updateDataBase() {
    // TODO(wim): make this method redundant by using streams to auto update
    // the in memory db
    _myBox.put('CARDLIST', myShops);
  }

  void sortType() {
    myShops.sort((a, b) => a['cardType'].compareTo(b['cardType']));
  }
}
