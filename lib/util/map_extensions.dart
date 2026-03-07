extension MapExtensions on Map<String, dynamic> {
  String? getString(String key) => this[key] as String?;
  int? getInt(String key) => this[key] as int?;
  bool? getBool(String key) => this[key] as bool?;
  List? getList(String key) => this[key] as List?;
}
