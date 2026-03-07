import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:cardabase/util/map_extensions.dart';
import 'package:flutter/material.dart';

class LoyaltyCard {
  const LoyaltyCard({
    required this.name,
    required this.data,
    required this.color,
    required this.barcodeType,
    required this.requiresAuth,
    required this.uniqueId,
    required this.tags,
    required this.notes,
    required this.frontImagePath,
    required this.backImagePath,
    required this.useFrontFaceOverlay,
    required this.hideTitle,
    required this.points,
  });

  LoyaltyCard.empty()
      : this(
          name: 'Card',
          data: '',
          color: null,
          barcodeType: BarcodeType.CodeEAN13,
          requiresAuth: false,
          uniqueId: generateUniqueId(),
          tags: {},
          notes: null,
          frontImagePath: null,
          backImagePath: null,
          useFrontFaceOverlay: false,
          hideTitle: false,
          points: 0,
        );

  final String name;
  final String data;
  final Color? color;
  final BarcodeType barcodeType;
  final bool requiresAuth;
  final String uniqueId;
  final Set<String> tags;
  final String? notes;
  final String? frontImagePath;
  final String? backImagePath;
  final bool useFrontFaceOverlay;
  final bool hideTitle;
  final int points;

  factory LoyaltyCard.fromDbModel(Map<String, dynamic> model) {
    final r = model.getInt('redValue');
    final g = model.getInt('greenValue');
    final b = model.getInt('blueValue');
    late final Color? color;
    if (r == null || g == null || b == null) {
      color = null;
    } else {
      color = Color.fromARGB(255, r, g, b);
    }

    final strBarcodeType = model.getString('cardType');

    return LoyaltyCard(
      name: model.getString('cardName') ?? '',
      data: model.getString('cardId') ?? '',
      color: color,
      barcodeType: strBarcodeType == null
          ? BarcodeType.CodeEAN13
          : parseBarcodeTypeStringFromDb(strBarcodeType),
      requiresAuth: model.getBool('hasPassword') ?? false,
      uniqueId: model.getString('uniqueId') ?? '',
      tags: model.getList('tags')?.whereType<String>().toSet() ?? {},
      notes: model.getString('note'),
      frontImagePath: model.getString('imagePathFront'),
      backImagePath: model.getString('imagePathBack'),
      useFrontFaceOverlay: model.getBool('useFrontFaceOverlay') ?? false,
      hideTitle: model.getBool('hideTitle') ?? false,
      points: model.getInt('pointsAmount') ?? 0,
    );
  }

  Map<String, dynamic> toDbModel() {
    final color = this.color;
    return {
      'cardName': name,
      'cardId': data,
      if (color != null) ...{
        'redValue': (color.r * 255).round(),
        'greenValue': (color.g * 255).round(),
        'blueValue': (color.b * 255).round(),
      },
      'cardType': barcodeType.getDbStringValue(),
      'hasPassword': requiresAuth,
      'uniqueId': uniqueId,
      'tags': tags.toList(),
      'note': notes,
      'imagePathFront': frontImagePath,
      'imagePathBack': backImagePath,
      'useFrontFaceOverlay': useFrontFaceOverlay,
      'hideTitle': hideTitle,
      'pointsAmount': points,
    };
  }

  factory LoyaltyCard.fromShare(String code) {
    // TODO(wim): why use custom sharing protocol? Use json instead.
    if (!code.startsWith('[') || !code.endsWith(']')) {
      throw FormatException(
        'Expected shared data to be in format of `[name, number, red, green, blue, cardType,hasPassword]`. But did not receive start or end brackets.',
      );
    }

    final List<String> rawList =
        code.replaceAll('[', '').replaceAll(']', '').split(', ');

    if (rawList.length < 7) {
      throw FormatException(
        'Expected shared data to be in format of `[name, number, red, green, blue, cardType,hasPassword]`. But did not receive enough elements.',
      );
    }

    final red = int.parse(rawList[2]);
    final green = int.parse(rawList[3]);
    final blue = int.parse(rawList[4]);

    return LoyaltyCard(
      name: rawList[0],
      data: rawList[1],
      color: Color.fromARGB(255, red, green, blue),
      barcodeType: parseBarcodeTypeStringFromDb(rawList[5]),
      requiresAuth: rawList[6] == 'true',
      uniqueId: generateUniqueId(),
      tags: {},
      notes: '',
      frontImagePath: null,
      backImagePath: null,
      useFrontFaceOverlay: false,
      hideTitle: false,
      points: 0,
    );
  }

  String toShareData() {
    final color = this.color ?? Colors.grey;
    final props = [
      name,
      data,
      (color.r * 255).toInt().toString(),
      (color.g * 255).toInt().toString(),
      (color.b * 255).toInt().toString(),
      barcodeType.getDbStringValue(),
      requiresAuth ? 'true' : 'false',
    ].join(', ');

    return '[$props]';
  }

  EditableLoyaltyCard editable() {
    return EditableLoyaltyCard(
      name: TextEditingController(text: 'Card'),
      data: TextEditingController(),
      color: ValueNotifier(null),
      barcodeType: ValueNotifier(BarcodeType.CodeEAN13),
      requiresAuth: ValueNotifier(false),
      uniqueId: ValueNotifier(generateUniqueId()),
      tags: ValueNotifier({}),
      notes: TextEditingController(),
      frontImagePath: ValueNotifier(null),
      backImagePath: ValueNotifier(null),
      useFrontFaceOverlay: ValueNotifier(false),
      hideTitle: ValueNotifier(false),
      points: ValueNotifier(0),
    );
  }
}

class EditableLoyaltyCard {
  EditableLoyaltyCard({
    required this.name,
    required this.data,
    required this.color,
    required this.barcodeType,
    required this.requiresAuth,
    required this.uniqueId,
    required this.tags,
    required this.notes,
    required this.frontImagePath,
    required this.backImagePath,
    required this.useFrontFaceOverlay,
    required this.hideTitle,
    required this.points,
  });

  final TextEditingController name;
  final TextEditingController data;
  final ValueNotifier<Color?> color;
  final ValueNotifier<BarcodeType> barcodeType;
  final ValueNotifier<bool> requiresAuth;
  final ValueNotifier<String> uniqueId;
  final ValueNotifier<Set<String>> tags;
  final TextEditingController notes;
  final ValueNotifier<String?> frontImagePath;
  final ValueNotifier<String?> backImagePath;
  final ValueNotifier<bool> useFrontFaceOverlay;
  final ValueNotifier<bool> hideTitle;
  final ValueNotifier<int> points;

  void readFrom(LoyaltyCard card) {
    name.text = card.name;
    data.text = card.data;
    color.value = card.color;
    barcodeType.value = card.barcodeType;
    requiresAuth.value = card.requiresAuth;
    uniqueId.value = card.uniqueId;
    tags.value = card.tags;
    notes.text = card.notes ?? '';
    frontImagePath.value = card.frontImagePath;
    backImagePath.value = card.backImagePath;
    useFrontFaceOverlay.value = card.useFrontFaceOverlay;
    hideTitle.value = card.hideTitle;
    points.value = card.points;
  }

  LoyaltyCard seal() {
    return LoyaltyCard(
      name: name.text,
      data: data.text,
      color: color.value,
      barcodeType: barcodeType.value,
      requiresAuth: requiresAuth.value,
      uniqueId: uniqueId.value,
      tags: tags.value,
      notes: notes.text.isEmpty ? null : notes.text,
      frontImagePath: frontImagePath.value,
      backImagePath: backImagePath.value,
      useFrontFaceOverlay: useFrontFaceOverlay.value,
      hideTitle: hideTitle.value,
      points: points.value,
    );
  }

  void dispose() {
    name.dispose();
    data.dispose();
    color.dispose();
    barcodeType.dispose();
    requiresAuth.dispose();
    uniqueId.dispose();
    tags.dispose();
    notes.dispose();
    frontImagePath.dispose();
    backImagePath.dispose();
    useFrontFaceOverlay.dispose();
    hideTitle.dispose();
    points.dispose();
  }
}
