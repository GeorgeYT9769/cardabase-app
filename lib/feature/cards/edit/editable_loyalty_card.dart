import 'package:barcode_widget/barcode_widget.dart' hide Barcode;
import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/list_notifier.dart';
import 'package:flutter/widgets.dart';

class EditableLoyaltyCard {
  const EditableLoyaltyCard({
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
  });

  EditableLoyaltyCard.createNew()
      : this(
          id: ValueNotifier(generateUniqueId()),
          barcode: EditableBarcode.createNew(),
          name: TextEditingController(),
          color: ValueNotifier(null),
          tags: ListNotifier(const []),
          notes: TextEditingController(),
          frontImagePath: ValueNotifier(null),
          backImagePath: ValueNotifier(null),
          useFrontImageOverlay: ValueNotifier(false),
          points: ValueNotifier(0),
          requiresAuth: ValueNotifier(false),
          hideName: ValueNotifier(false),
          createdAt: ValueNotifier(DateTime.now().toUtc()),
        );

  factory EditableLoyaltyCard.fromValue(LoyaltyCard value) {
    return EditableLoyaltyCard(
      id: ValueNotifier(value.id),
      barcode: EditableBarcode.fromValue(value.barcode),
      name: TextEditingController(text: value.name),
      color: ValueNotifier(value.color),
      tags: ListNotifier(value.tags.toList()),
      notes: TextEditingController(text: value.notes),
      frontImagePath: ValueNotifier(value.frontImagePath),
      backImagePath: ValueNotifier(value.backImagePath),
      useFrontImageOverlay: ValueNotifier(value.useFrontImageOverlay),
      points: ValueNotifier(value.points),
      requiresAuth: ValueNotifier(value.requiresAuth),
      hideName: ValueNotifier(value.hideName),
      createdAt: ValueNotifier(value.createdAt),
    );
  }

  // Some fields feel like they should be readonly instead of `ValueNotifier`.
  // This is done to enable the `loadValue` method.

  final ValueNotifier<String> id;
  final EditableBarcode barcode;
  final TextEditingController name;
  final ValueNotifier<Color?> color;
  final ListNotifier<String> tags;
  final TextEditingController notes;
  final ValueNotifier<String?> frontImagePath;
  final ValueNotifier<String?> backImagePath;
  final ValueNotifier<bool> useFrontImageOverlay;
  final ValueNotifier<int> points;
  final ValueNotifier<bool> requiresAuth;
  final ValueNotifier<bool> hideName;
  final ValueNotifier<DateTime> createdAt;

  void loadValue(LoyaltyCard value) {
    id.value = value.id;
    barcode.loadValue(value.barcode);
    name.text = value.name;
    color.value = value.color;
    tags.value = value.tags.toList(growable: false);
    notes.text = value.notes ?? '';
    frontImagePath.value = value.frontImagePath;
    backImagePath.value = value.backImagePath;
    useFrontImageOverlay.value = value.useFrontImageOverlay;
    points.value = value.points;
    requiresAuth.value = value.requiresAuth;
    hideName.value = value.hideName;
  }

  LoyaltyCard seal() {
    return LoyaltyCard(
      id: id.value,
      barcode: barcode.seal(),
      name: name.text,
      color: color.value,
      tags: tags.value.toSet(),
      notes: notes.text.isEmpty ? null : notes.text,
      frontImagePath: frontImagePath.value,
      backImagePath: backImagePath.value,
      useFrontImageOverlay: useFrontImageOverlay.value,
      points: points.value,
      requiresAuth: requiresAuth.value,
      hideName: hideName.value,
      createdAt: createdAt.value,
      lastModifiedAt: DateTime.now().toUtc(),
    );
  }

  void dispose() {
    id.dispose();
    barcode.dispose();
    name.dispose();
    color.dispose();
    tags.dispose();
    notes.dispose();
    frontImagePath.dispose();
    backImagePath.dispose();
    useFrontImageOverlay.dispose();
    points.dispose();
    requiresAuth.dispose();
    hideName.dispose();
  }
}

class EditableBarcode {
  EditableBarcode({
    required this.data,
    required this.type,
  });

  EditableBarcode.createNew()
      : this(
          data: TextEditingController(),
          type: ValueNotifier(BarcodeType.CodeEAN13),
        );

  factory EditableBarcode.fromValue(Barcode value) {
    return EditableBarcode(
      data: TextEditingController(text: value.data),
      type: ValueNotifier(value.type),
    );
  }

  final TextEditingController data;
  final ValueNotifier<BarcodeType> type;

  void loadValue(Barcode value) {
    data.text = value.data;
    type.value = value.type;
  }

  Barcode seal() {
    return Barcode(
      data: data.text,
      type: type.value,
    );
  }

  void dispose() {
    data.dispose();
    type.dispose();
  }
}
