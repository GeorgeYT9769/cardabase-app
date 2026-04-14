import 'package:flutter/painting.dart';

extension MapExtensions on Map<String, dynamic> {
  String? getString(String key) => this[key] as String?;

  int? getInt(String key) => this[key] as int?;

  bool? getBool(String key) => this[key] as bool?;

  List? getList(String key) => this[key] as List?;

  Color? getColor(String key) {
    final strColor = getString('color');
    if (strColor == null) {
      return null;
    }

    final strIntColor = strColor.startsWith('#')
        ? strColor.substring(1, strColor.length)
        : strColor;

    final intColor = int.tryParse(strIntColor, radix: 16);
    if (intColor == null) {
      return null;
    }
    return Color(intColor);
  }
}
