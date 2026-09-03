import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/data/hive.dart';
import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/editable_loyalty_card.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:cardabase/util/list_extensions.dart';
import 'package:cardabase/util/map_extensions.dart';
import 'package:cardabase/util/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive_ce/hive.dart';

export 'package:barcode_widget/barcode_widget.dart' show BarcodeType;

part 'loyalty_card.g.dart';

typedef LoyaltyCardsBox = Box<LoyaltyCard>;

@HiveType(typeId: HiveTypeIds.loyaltyCard)
class LoyaltyCard {
  static const Color defaultColor = Colors.grey;

  LoyaltyCard({
    required this.id,
    required this.barcode,
    required this.name,
    required this.color,
    required this.tags,
    required this.notes,
    required this.frontImagePath,
    required this.backImagePath,
    required this.useFrontImageOverlay,
    required this.points,
    required this.requiresAuth,
    required this.hideName,
    required DateTime? createdAt,
    required DateTime? lastModifiedAt,
    required this.usePoints,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        lastModifiedAt = lastModifiedAt ?? DateTime.now().toUtc();

  /// [id] is the unique identifier of the card.
  @HiveField(0)
  final String id;

  /// [barcode] contains the information about the barcode on the card.
  @HiveField(1)
  final Barcode barcode;

  /// [name] is a name which the user gave to the card. E.g. the name of the
  /// shop where the card is issued.
  @HiveField(2)
  final String name;

  /// [color] is a color which the user can assign to the card. This color is
  /// used in various places as background or border color.
  @HiveField(3)
  final Color? color;

  /// [tags] is a list of arbitrary values by which the card can be categorized.
  @HiveField(4)
  final Set<String> tags;

  /// [notes] is a free text field in which the user can write a description,
  /// or other notes.
  @HiveField(5)
  final String? notes;

  /// [frontImagePath] is the path to the image on the front of the card.
  @HiveField(6)
  final String? frontImagePath;

  /// [backImagePath] is the path to the image on the back of the card.
  @HiveField(7)
  final String? backImagePath;

  /// [useFrontImageOverlay] specifies whether the [frontImagePath] should be
  /// used when displaying the card in the overview. Otherwise, the [color] is
  /// used.
  @HiveField(8)
  final bool useFrontImageOverlay;

  /// [points] is the amount of points stored on the card.
  @HiveField(9)
  final int points;

  /// [requiresAuth] indicates whether the user should provide their credential
  /// when opening/modifying the card.
  @HiveField(10)
  final bool requiresAuth;

  /// [hideName] indicates whether the name of the card should be hidden on the
  /// front of the card. This can be useful when using the [frontImagePath].
  /// E.g.: if the name of the shop is already displayed on the image, the name
  /// of card does not need to be displayed again.
  @HiveField(11)
  final bool hideName;

  /// [createdAt] is the timestamp (UTC) at which the card was created.
  @HiveField(12)
  final DateTime createdAt;

  /// [lastModifiedAt] is the timestamp (UTC) at which the card was last modified.
  /// This is used by default for sorting.
  @HiveField(13)
  final DateTime lastModifiedAt;

  /// [usePoints] whether the card uses Points amount
  @HiveField(14, defaultValue: false)
  final bool usePoints;

  Color get nonNullColor => color ?? defaultColor;

  EditableLoyaltyCard editable() => EditableLoyaltyCard.fromValue(this);

  String toJson() {
    return jsonEncode(toJsonMap());
  }

  @Deprecated('this method is only here for backwards compatibility.')
  factory LoyaltyCard.fromLegacySharing(String value) {
    if (!value.startsWith('[') || !value.endsWith(']')) {
      throw FormatException(
        'Expected shared data to be in format of `[name, number, red, green, blue, cardType,hasPassword]`. But did not receive start or end brackets.',
      );
    }

    final List<String> rawList =
        value.replaceAll('[', '').replaceAll(']', '').split(', ');

    if (rawList.length < 7) {
      throw FormatException(
        'Expected shared data to be in format of `[name, number, red, green, blue, cardType,hasPassword]`. But did not receive enough elements.',
      );
    }

    final red = int.parse(rawList[2]);
    final green = int.parse(rawList[3]);
    final blue = int.parse(rawList[4]);

    final now = DateTime.now().toUtc();
    return LoyaltyCard(
      id: generateUniqueId(),
      name: rawList[0],
      barcode: Barcode(
        data: rawList[1],
        type: parseBarcodeTypeStringFromDb(rawList[5]),
      ),
      color: Color.fromARGB(255, red, green, blue),
      requiresAuth: rawList[6] == 'true',
      tags: {},
      notes: null,
      frontImagePath: null,
      backImagePath: null,
      useFrontImageOverlay: false,
      hideName: false,
      points: 0,
      createdAt: now,
      lastModifiedAt: now,
      usePoints: false,
    );
  }

  @Deprecated('this method is only here for backwards compatibility.')
  factory LoyaltyCard.fromLegacyExport(String value) {
    final trimmed = value.trim();

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final cleaned = trimmed.substring(1, trimmed.length - 1); // remove { }
      final fields = cleaned.split(',').map((e) => e.trim()).toList();
      final Map<String, dynamic> cardMap = {};
      for (final field in fields) {
        final kv = field.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim();
          final value = kv.sublist(1).join(':').trim();
          cardMap[key] = value;
        }
      }

      if (cardMap.isEmpty) {
        throw Exception('received an empty card on import');
      }

      if (cardMap.isNotEmpty) {
        final strType = cardMap.getString('cardType')?.nullWhenEmpty;

        final now = DateTime.now().toUtc();
        final red = cardMap.getInt('redValue');
        final green = cardMap.getInt('greenValue');
        final blue = cardMap.getInt('blueValue');

        final points = cardMap.getInt('pointsAmount') ?? 0;

        return LoyaltyCard(
          id: generateUniqueId(),
          barcode: Barcode(
            data: cardMap['cardId'] ?? '',
            type:
                strType == null ? null : parseBarcodeTypeStringFromDb(strType),
          ),
          name: cardMap['cardName'] ?? '',
          color: red == null || green == null || blue == null
              ? null
              : Color.fromARGB(255, red, green, blue),
          tags: {},
          notes: cardMap.getString('note')?.nullWhenEmpty,
          frontImagePath: null,
          backImagePath: null,
          useFrontImageOverlay: false,
          points: points,
          requiresAuth: cardMap.getBool('hasPassword') ?? false,
          hideName: false,
          createdAt: now,
          lastModifiedAt: now,
          usePoints: points != 0 || cardMap.containsKey('pointsAmount'),
        );
      }
    }

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final cleaned = trimmed.substring(1, trimmed.length - 1);
      final rawList = cleaned.split(',').map((e) => e.trim()).toList();
      return LoyaltyCard.fromLegacyValueList(rawList);
    }

    throw Exception('failed to parse card');
  }

  @Deprecated('this method is only here for backwards compatibility.')
  factory LoyaltyCard.fromLegacyValueList(List rawList) {
    if (rawList.length < 7) {
      throw FormatException(
        'Expected data to be in format of `[name, number, red, green, blue, cardType,hasPassword]`. But did not receive enough elements.',
      );
    }

    final now = DateTime.now().toUtc();
    final red = rawList.getIntAt(2);
    final green = rawList.getIntAt(3);
    final blue = rawList.getIntAt(4);
    final strType = rawList.getStringAt(5);

    return LoyaltyCard(
      id: generateUniqueId(),
      name: rawList.getStringAt(0) ?? '',
      barcode: Barcode(
        data: rawList.getStringAt(1) ?? '',
        type: strType == null ? null : parseBarcodeTypeStringFromDb(strType),
      ),
      color: red == null || green == null || blue == null
          ? null
          : Color.fromARGB(255, red, green, blue),
      requiresAuth: rawList.getBoolAt(6) ?? false,
      tags: {},
      notes: '',
      frontImagePath: null,
      backImagePath: null,
      useFrontImageOverlay: false,
      hideName: false,
      points: 0,
      createdAt: now,
      lastModifiedAt: now,
      usePoints: false,
    );
  }

  factory LoyaltyCard.fromJson(String value) {
    final jsonMap = jsonDecode(value) as Map<String, dynamic>?;
    if (jsonMap == null) {
      throw Exception('unknown data format from sharing');
    }
    return LoyaltyCard.fromJsonMap(jsonMap);
  }

  factory LoyaltyCard.fromJsonMap(Map<String, dynamic> jsonMap) {
    final now = DateTime.now().toUtc();
    final points =
        jsonMap.getInt('points') ?? jsonMap.getInt('pointsAmount') ?? 0;
    return LoyaltyCard(
      id: jsonMap.getString('id') ?? generateUniqueId(),
      barcode: jsonMap.getObject('barcode', Barcode.fromJsonMap) ??
          (throw Exception('barcode is missing')),
      name: jsonMap.getString('name') ?? (throw Exception('name is missing')),
      color: jsonMap.getColor('color'),
      tags: jsonMap.getList('tags')?.whereType<String>().toSet() ?? {},
      notes: jsonMap.getString('notes'),
      frontImagePath: null,
      backImagePath: null,
      useFrontImageOverlay: jsonMap.getBool('useFrontImageOverlay') ?? false,
      points: points,
      requiresAuth: jsonMap.getBool('requiresAuth') ?? false,
      hideName: jsonMap.getBool('hideName') ?? false,
      createdAt: now,
      lastModifiedAt: now,
      usePoints: jsonMap.getBool('usePoints') ??
          (points != 0 ||
              jsonMap.containsKey('points') ||
              jsonMap.containsKey('pointsAmount')),
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'barcode': barcode.toJsonMap(),
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      if (color != null)
        'color': color?.toHexString(
          includeHashSign: true,
          toUpperCase: true,
        ),
      if (tags.isNotEmpty) 'tags': tags.toList(growable: false),
      if (notes != null) 'notes': notes,
      'points': points,
      if (requiresAuth != false) 'requiresAuth': requiresAuth,
      if (hideName != false) 'hideName': hideName,
      if (useFrontImageOverlay != false)
        'useFrontImageOverlay': useFrontImageOverlay,
      'usePoints': usePoints,
    };
  }

  LoyaltyCard copyWith({
    String? id,
    Barcode? barcode,
    String? name,
    Color? color,
    Set<String>? tags,
    String? notes,
    String? frontImagePath,
    String? backImagePath,
    bool? useFrontImageOverlay,
    int? points,
    bool? requiresAuth,
    bool? hideName,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    bool? usePoints,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      useFrontImageOverlay: useFrontImageOverlay ?? this.useFrontImageOverlay,
      points: points ?? this.points,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      hideName: hideName ?? this.hideName,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      usePoints: usePoints ?? this.usePoints,
    );
  }

  LoyaltyCard clone() {
    final now = DateTime.now().toUtc();
    return LoyaltyCard(
      id: generateUniqueId(),
      barcode: barcode.clone(),
      name: name,
      color: color,
      tags: tags,
      notes: notes,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
      useFrontImageOverlay: useFrontImageOverlay,
      points: points,
      requiresAuth: requiresAuth,
      hideName: hideName,
      createdAt: now,
      lastModifiedAt: now,
      usePoints: usePoints,
    );
  }
}

@HiveType(typeId: HiveTypeIds.barcode)
class Barcode {
  const Barcode({
    required this.data,
    required this.type,
  });

  @HiveField(0)
  final String data;
  @HiveField(1)
  final BarcodeType? type;

  EditableBarcode editable() => EditableBarcode.fromValue(this);

  factory Barcode.fromJsonMap(Map<String, dynamic> map) {
    final strType = map.getString('type');
    return Barcode(
      data:
          map.getString('data') ?? (throw Exception('barcode data is missing')),
      type: strType == null
          ? null
          : BarcodeType.values.firstWhere(
              (value) => value.name == strType,
              orElse: () => throw Exception('unknown barcodeType: $strType'),
            ),
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'data': data,
      if (type != null) 'type': type!.name,
    };
  }

  Barcode clone() {
    return Barcode(
      data: data,
      type: type,
    );
  }
}

extension LoyaltyCardListExtensions on Iterable<LoyaltyCard> {
  String serializeToJson() {
    return jsonEncode(map((card) => card.toJsonMap()).toList(growable: false));
  }
}
