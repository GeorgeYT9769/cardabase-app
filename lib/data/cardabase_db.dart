import 'dart:math';

import 'package:cardabase/data/loyalty_card.dart';
import 'package:cardabase/data/unique_id.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class CardabaseDb {
  List myShops = [];

  final _myBox = Hive.box('mybox');

  LoyaltyCard getAt(int index) => _mapEntryToModel(myShops[index]);

  void upsert(LoyaltyCard card) {
    final index = _indexOf(card.uniqueId);
    if (index < 0) {
      myShops.add(card.toDbModel());
    } else {
      myShops[index] = card.toDbModel();
    }
    updateDataBase();
  }

  Iterable<LoyaltyCard> getAll() {
    return myShops.map(_mapEntryToModel);
  }

  LoyaltyCard? remove(String id) {
    final index = _indexOf(id);
    if (index < 0) {
      return null;
    }
    final removed = myShops.removeAt(index);
    updateDataBase();
    return _mapEntryToModel(removed);
  }

  void move(String id, int Function(int oldIndex) indexManipulator) {
    final index = _indexOf(id);
    if (index < 0) {
      throw Exception('no card found with the given id');
    }
    final newIndex = max(0, min(indexManipulator(index), myShops.length - 1));
    moveByIndex(index, newIndex);
  }

  void moveByIndex(int oldIndex, int newIndex) {
    final card = myShops.removeAt(oldIndex);
    myShops.insert(newIndex, card);
    updateDataBase();
  }

  void duplicate(String id) {
    final index = _indexOf(id);
    if (index < 0) {
      throw Exception('no card found with the given id');
    }
    final card = getAt(index).editable();
    card.uniqueId.value = generateUniqueId();
    myShops.insert(index + 1, card.seal().toDbModel());
    updateDataBase();
  }

  bool exists(String id) {
    return _indexOf(id) >= 0;
  }

  int _indexOf(String id) {
    var i = 0;
    for (final card in getAll()) {
      if (card.uniqueId == id) {
        return i;
      }
      i++;
    }
    return -1;
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
