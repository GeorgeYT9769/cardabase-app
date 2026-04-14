extension StringExtensions on String {
  String? get nullWhenEmpty {
    return isEmpty ? null : this;
  }
}
