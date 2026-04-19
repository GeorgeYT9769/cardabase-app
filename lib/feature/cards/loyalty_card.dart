import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/data/hive.dart';
import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/edit/editable_loyalty_card.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:cardabase/util/map_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive_ce/hive.dart';

part 'loyalty_card.g.dart';

typedef LoyaltyCardsBox = Box<LoyaltyCard>;

@HiveType(typeId: HiveTypeIds.loyaltyCard)
class LoyaltyCard {
  static const Color defaultColor = Colors.grey;

  const LoyaltyCard({
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
    required this.createdAt,
    required this.lastModifiedAt,
  });

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
      notes: '',
      frontImagePath: null,
      backImagePath: null,
      useFrontImageOverlay: false,
      hideName: false,
      points: 0,
      createdAt: now,
      lastModifiedAt: now,
    );
  }

  @Deprecated('this method is only here for backwards compatibility.')
  factory LoyaltyCard.fromLegacyExport(String value) {
    final trimmed = value.trim();
    final now = DateTime.now().toUtc();

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
        final strType = cardMap['cardType'];

        final red = int.tryParse(cardMap['redValue']) ?? 0;
        final green = int.tryParse(cardMap['greenValue']) ?? 0;
        final blue = int.tryParse(cardMap['blueValue']) ?? 0;

        return LoyaltyCard(
          id: generateUniqueId(),
          barcode: Barcode(
            data: cardMap['cardId'] ?? '',
            type: parseBarcodeTypeStringFromDb(strType),
          ),
          name: cardMap['cardName'] ?? '',
          color: Color.fromARGB(255, red, green, blue),
          tags: {},
          notes: cardMap['note'],
          frontImagePath: null,
          backImagePath: null,
          useFrontImageOverlay: false,
          points: int.tryParse(cardMap['pointsAmount']) ?? 0,
          requiresAuth:
              ((cardMap['hasPassword'] as String?)?.toLowerCase() == 'true'),
          hideName: false,
          createdAt: now,
          lastModifiedAt: now,
        );
      }
    }

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final cleaned = trimmed.substring(1, trimmed.length - 1);
      final rawList = cleaned.split(',').map((e) => e.trim()).toList();
      if (rawList.length < 7) {
        throw FormatException(
          'Expected shared data to be in format of `[name, number, red, green, blue, cardType,hasPassword]`. But did not receive enough elements.',
        );
      }

      final red = int.parse(rawList[2]);
      final green = int.parse(rawList[3]);
      final blue = int.parse(rawList[4]);

      return LoyaltyCard(
        id: generateUniqueId(),
        name: rawList[0],
        barcode: Barcode(
          data: rawList[1],
          type: BarcodeType.values.firstWhere(
            (value) => value.name == rawList[5],
            orElse: () => throw Exception('unknown barcodeType: ${rawList[5]}'),
          ),
        ),
        color: Color.fromARGB(255, red, green, blue),
        requiresAuth: rawList[6] == 'true',
        tags: {},
        notes: '',
        frontImagePath: null,
        backImagePath: null,
        useFrontImageOverlay: false,
        hideName: false,
        points: 0,
        createdAt: now,
        lastModifiedAt: now,
      );
    }

    throw Exception('failed to parse card');
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
      useFrontImageOverlay: false,
      points: jsonMap.getInt('points') ?? 0,
      requiresAuth: jsonMap.getBool('requiresAuth') ?? false,
      hideName: jsonMap.getBool('hideName') ?? false,
      createdAt: now,
      lastModifiedAt: now,
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
      if (points != 0) 'points': points,
      if (requiresAuth != false) 'requiresAuth': requiresAuth,
      if (hideName != false) 'hideName': hideName,
    };
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
  final BarcodeType type;

  EditableBarcode editable() => EditableBarcode.fromValue(this);

  factory Barcode.fromJsonMap(Map<String, dynamic> map) {
    final strType = map.getString('type');
    return Barcode(
      data:
          map.getString('data') ?? (throw Exception('barcode data is missing')),
      type: BarcodeType.values.firstWhere(
        (value) => value.name == strType,
        orElse: () => throw Exception('unknown barcodeType: $strType'),
      ),
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'data': data,
      'type': type.name,
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
    return jsonEncode(map((card) => card.toJsonMap()));
  }
}
