extension ListExtensions<E> on List<E> {
  void sortMapped<T>(
    T Function(E element) selector,
    int Function(T a, T b) compare,
  ) {
    final sorted = map((element) => _Tuple<E, T>(element, selector(element)))
        .toList(growable: false)
      ..sort((tuple1, tuple2) => compare(tuple1.b, tuple2.b));

    for (var i = 0; i < sorted.length; i++) {
      this[i] = sorted[i].a;
    }
  }

  String? getStringAt(int index) {
    final value = _elementAt(index);
    return value is String ? value : null;
  }

  int? getIntAt(int index) {
    return switch (_elementAt(index)) {
      int i => i,
      String s => int.tryParse(s),
      _ => null,
    };
  }

  bool? getBoolAt(int index) {
    return switch (_elementAt(index)) {
      bool b => b,
      String s => bool.tryParse(s),
      _ => null,
    };
  }

  E? _elementAt(int index) {
    if (index < 0 || index >= length) {
      return null;
    }
    return this[index];
  }
}

class _Tuple<A, B> {
  const _Tuple(this.a, this.b);

  final A a;
  final B b;

  @override
  bool operator ==(Object other) {
    return other is _Tuple<A, B> && other.a == a && other.b == b;
  }

  @override
  int get hashCode => 18734 ^ a.hashCode ^ b.hashCode;
}
