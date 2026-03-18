import 'dart:math';

import 'package:flutter/foundation.dart';

class ListNotifier<T> extends ChangeNotifier
    implements ValueListenable<List<T>>, List<T> {
  ListNotifier(
    List<T> value,
  ) : _value = value.toList(growable: true);

  List<T> _value;

  @override
  T get first => _value.first;

  @override
  set first(T value) {
    _value.first = value;
    notifyListeners();
  }

  @override
  T get last => _value.last;

  @override
  set last(T value) {
    _value.last = value;
    notifyListeners();
  }

  @override
  int get length => _value.length;

  @override
  set length(int value) {
    _value.length = value;
    notifyListeners();
  }

  @override
  List<T> operator +(List<T> other) => _value + other;

  @override
  T operator [](int index) => _value[index];

  @override
  void operator []=(int index, T value) {
    _value[index] = value;
    notifyListeners();
  }

  @override
  void add(T element) {
    _value.add(element);
    notifyListeners();
  }

  @override
  void addAll(Iterable<T> iterable) {
    _value.addAll(iterable);
    notifyListeners();
  }

  @override
  bool any(bool Function(T element) test) => _value.any(test);

  @override
  Map<int, T> asMap() => _value.asMap();

  @override
  List<R> cast<R>() => _value.cast();

  @override
  void clear() => _value.clear();

  @override
  bool contains(Object? element) => _value.contains(element);

  @override
  T elementAt(int index) => _value.elementAt(index);

  @override
  bool every(bool Function(T element) test) => _value.every(test);

  @override
  Iterable<TOut> expand<TOut>(Iterable<TOut> Function(T element) toElements) {
    return _value.expand(toElements);
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    _value.fillRange(start, end, fillValue);
    notifyListeners();
  }

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _value.firstWhere(test, orElse: orElse);
  }

  @override
  TOut fold<TOut>(
    TOut initialValue,
    TOut Function(TOut previousValue, T element) combine,
  ) {
    return _value.fold(initialValue, combine);
  }

  @override
  Iterable<T> followedBy(Iterable<T> other) => _value.followedBy(other);

  @override
  void forEach(void Function(T element) action) => _value.forEach(action);

  @override
  Iterable<T> getRange(int start, int end) => _value.getRange(start, end);

  @override
  int indexOf(T element, [int start = 0]) => _value.indexOf(element, start);

  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) {
    return _value.indexWhere(test, start);
  }

  @override
  void insert(int index, T element) {
    _value.insert(index, element);
    notifyListeners();
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    _value.insertAll(index, iterable);
    notifyListeners();
  }

  @override
  bool get isEmpty => _value.isEmpty;

  @override
  bool get isNotEmpty => _value.isNotEmpty;

  @override
  Iterator<T> get iterator => _value.iterator;

  @override
  String join([String separator = '']) => _value.join(separator);

  @override
  int lastIndexOf(T element, [int? start]) {
    return _value.lastIndexOf(element, start);
  }

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    return _value.lastIndexWhere(test, start);
  }

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _value.lastWhere(test, orElse: orElse);
  }

  @override
  Iterable<TOut> map<TOut>(TOut Function(T e) toElement) =>
      _value.map(toElement);

  @override
  T reduce(T Function(T value, T element) combine) => _value.reduce(combine);

  @override
  bool remove(Object? value) {
    final hasRemoved = _value.remove(value);
    notifyListeners();
    return hasRemoved;
  }

  @override
  T removeAt(int index) {
    final removed = _value.removeAt(index);
    notifyListeners();
    return removed;
  }

  @override
  T removeLast() {
    final removed = _value.removeLast();
    notifyListeners();
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    _value.removeRange(start, end);
    notifyListeners();
  }

  @override
  void removeWhere(bool Function(T element) test) {
    _value.removeWhere(test);
    notifyListeners();
  }

  @override
  void replaceRange(int start, int end, Iterable<T> replacements) {
    _value.replaceRange(start, end, replacements);
    notifyListeners();
  }

  @override
  void retainWhere(bool Function(T element) test) {
    _value.retainWhere(test);
    notifyListeners();
  }

  @override
  Iterable<T> get reversed => _value.reversed;

  @override
  void setAll(int index, Iterable<T> iterable) {
    _value.setAll(index, iterable);
    notifyListeners();
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    _value.setRange(start, end, iterable, skipCount);
    notifyListeners();
  }

  @override
  void shuffle([Random? random]) {
    _value.shuffle(random);
    notifyListeners();
  }

  @override
  T get single => _value.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    return _value.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<T> skip(int count) => _value.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _value.skipWhile(test);

  @override
  void sort([int Function(T a, T b)? compare]) {
    _value.sort(compare);
    notifyListeners();
  }

  @override
  List<T> sublist(int start, [int? end]) => _value.sublist(start, end);

  @override
  Iterable<T> take(int count) => _value.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _value.takeWhile(test);

  @override
  List<T> toList({bool growable = true}) => _value.toList(growable: growable);

  @override
  Set<T> toSet() => _value.toSet();

  @override
  List<T> get value => _value.toList(growable: false);

  set value(List<T> elements) {
    if (_value == elements) {
      return;
    }
    _value = elements.toList(growable: true);
    notifyListeners();
  }

  @override
  Iterable<T> where(bool Function(T element) test) => _value.where(test);

  @override
  Iterable<TOut> whereType<TOut>() => _value.whereType();
}
