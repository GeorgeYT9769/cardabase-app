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
