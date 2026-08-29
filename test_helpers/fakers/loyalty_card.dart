import 'package:barcode_widget/barcode_widget.dart' as widget;
import 'package:cardabase/feature/cards/barcode_helpers.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:faker/faker.dart' hide Color;

import 'flutter.dart';
import 'random.dart';

extension LoyaltyCardFakerExtensions on Faker {
  LoyaltyCardFaker get loyaltyCards => LoyaltyCardFaker(this);
}

class LoyaltyCardFaker {
  const LoyaltyCardFaker(this.faker);

  static int cardCount = 0;

  final Faker faker;

  String cardId() {
    return 'test-card-${cardCount++}';
  }

  String cardName() {
    return faker.company.name().replaceAll(',', '');
  }

  Barcode barcode() {
    final type = faker.randomGenerator.element(BarcodeType.values);
    return Barcode(
      type: type,
      data: barcodeData(type),
    );
  }

  String barcodeData(BarcodeType type) {
    return switch (type) {
      BarcodeType.CodeITF16 => codeITF16(),
      BarcodeType.CodeITF14 => codeITF14(),
      BarcodeType.CodeEAN13 => codeEAN13(),
      BarcodeType.CodeEAN8 => codeEAN8(),
      BarcodeType.CodeEAN5 => codeEAN5(),
      BarcodeType.CodeEAN2 => codeEAN2(),
      BarcodeType.CodeISBN => codeISBN(),
      BarcodeType.Code39 => code39(),
      BarcodeType.Code93 => code93(),
      BarcodeType.CodeUPCA => codeUPCA(),
      BarcodeType.CodeUPCE => codeUPCE(),
      BarcodeType.Code128 => code128(),
      BarcodeType.GS128 => gs128(),
      BarcodeType.Telepen => telepen(),
      BarcodeType.QrCode => qrCode(),
      BarcodeType.Codabar => codabar(),
      BarcodeType.PDF417 => pdf417(),
      BarcodeType.DataMatrix => dataMatrix(),
      BarcodeType.Aztec => aztec(),
      BarcodeType.Rm4scc => rm4scc(),
      BarcodeType.Postnet => postnet(),
      BarcodeType.Itf => itf(),
    };
  }

  // ---------------------------------------------------------
  // barcodes
  // ----------------------------------------------------------------

  String codeITF16() => _withGs1CheckDigit(faker.digits(15));

  String codeITF14() => _withGs1CheckDigit(faker.digits(13));

  String codeEAN13() => _withGs1CheckDigit(faker.digits(12));

  String codeEAN8() => _withGs1CheckDigit(faker.digits(7));

  String codeUPCA() => _withGs1CheckDigit(faker.digits(11));

  String codeUPCE() {
    final barcode = widget.Barcode.upcE();
    for (var attempt = 0; attempt < 1000; attempt++) {
      final candidate = '0${faker.digits(7)}';
      if (barcode.isValid(candidate)) {
        return candidate;
      }
    }
    throw StateError('failed to fake a upc-e');
  }

  String codeISBN() => _withGs1CheckDigit('978${faker.digits(9)}');

  String codeEAN5() => faker.digits(5);

  String codeEAN2() => faker.digits(2);

  String itf() => faker.digits(faker.randomGenerator.integer(6, min: 2) * 2);

  String postnet() {
    final length = faker.randomGenerator.element([5, 9, 11]);
    return faker.digits(length);
  }

  String code39() {
    return faker.stringFrom('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-. \$/+%', 8);
  }

  String code93() {
    return faker.stringFrom('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-. \$/+%', 8);
  }

  String code128() => faker.lorem.word();

  String gs128() => '(01)${codeITF14()}';

  String telepen() {
    return faker.stringFrom('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 8);
  }

  String rm4scc() {
    return faker.stringFrom('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 7);
  }

  String codabar() => faker.digits(8);

  String qrCode() => faker.internet.httpsUrl();

  String pdf417() => faker.lorem.sentence();

  String dataMatrix() => faker.lorem.sentence();

  String aztec() => faker.lorem.sentence();

  String _withGs1CheckDigit(String digits) => '$digits${gs1CheckDigit(digits)}';

  /// A card without any of the extras: no pictures, no password, its name on
  /// the front and no points.
  LoyaltyCard simpleCard() {
    final faked = card();
    return LoyaltyCard(
      id: faked.id,
      barcode: faked.barcode,
      name: faked.name,
      color: faked.color,
      tags: faked.tags,
      notes: faked.notes,
      frontImagePath: null,
      backImagePath: null,
      useFrontImageOverlay: false,
      points: 0,
      requiresAuth: false,
      hideName: false,
      createdAt: faked.createdAt,
      lastModifiedAt: faked.lastModifiedAt,
      usePoints: false,
    );
  }

  LoyaltyCard card() {
    return LoyaltyCard(
      id: cardId(),
      barcode: barcode(),
      name: cardName(),
      color: faker.nullOr(faker.flutter().color),
      tags: faker.randomGenerator
          .amount((_) => faker.lorem.word(), 5, min: 0)
          .toSet(),
      notes: faker.nullOr(faker.lorem.sentence),
      frontImagePath: faker.nullOr(faker.flutter().filePath),
      backImagePath: faker.nullOr(faker.flutter().filePath),
      useFrontImageOverlay: faker.randomGenerator.boolean(),
      points: faker.randomGenerator.integer(100, min: 1),
      requiresAuth: faker.randomGenerator.boolean(),
      hideName: faker.randomGenerator.boolean(),
      createdAt: faker.flutter().utcDateTime(minYear: 2024, maxYear: 2025),
      lastModifiedAt: faker.flutter().utcDateTime(minYear: 2025),
      usePoints: faker.randomGenerator.boolean(),
    );
  }

  String legacyShareCode() {
    final code = barcode();
    final color = faker.nullOr(faker.flutter().color);
    final props = [
      cardName(),
      code.data,
      color == null ? null : (color.r * 255.0).round().clamp(0, 255),
      color == null ? null : (color.g * 255.0).round().clamp(0, 255),
      color == null ? null : (color.b * 255.0).round().clamp(0, 255),
      code.type?.getDbStringValue(),
      faker.randomGenerator.boolean(),
    ].join(', ');
    return '[$props]';
  }

  /// A card as an older version exported it: a line of `key: value` pairs.
  String legacyExportEntry({
    String? name,
    String? data,
    String? barcodeType = 'CardType.ean13',
    int? red = 1,
    int? green = 2,
    int? blue = 3,
    bool requiresAuth = false,
    String? uniqueId,
    String? note,
    int? points,
  }) {
    final fields = <String, Object?>{
      'cardName': name ?? cardName(),
      'cardId': data ?? codeEAN13(),
      if (red != null) 'redValue': red,
      if (green != null) 'greenValue': green,
      if (blue != null) 'blueValue': blue,
      if (barcodeType != null) 'cardType': barcodeType,
      'hasPassword': requiresAuth,
      'uniqueId': uniqueId ?? cardId(),
      if (note != null) 'note': note,
      if (points != null) 'pointsAmount': points,
    };
    final body = fields.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return '{$body}';
  }

  /// A card as the oldest versions stored and exported it: a bare list.
  String legacyExportListEntry({
    String? name,
    String? data,
    int red = 158,
    int green = 158,
    int blue = 158,
    String barcodeType = 'CardType.ean13',
    bool requiresAuth = false,
  }) {
    return '[${name ?? cardName()}, ${data ?? codeEAN13()}, '
        '$red, $green, $blue, $barcodeType, $requiresAuth]';
  }

  /// The map an older version kept in its box, which the migration reads.
  Map<String, dynamic> legacyDbModel({
    String? name,
    String? data,
    String? barcodeType = 'CardType.ean13',
    int? red = 1,
    int? green = 2,
    int? blue = 3,
    bool requiresAuth = false,
    String? uniqueId,
    List<String> tags = const [],
    String? note,
    int? points,
  }) {
    return {
      'cardName': name ?? cardName(),
      'cardId': data ?? codeEAN13(),
      if (barcodeType != null) 'cardType': barcodeType,
      if (red != null) 'redValue': red,
      if (green != null) 'greenValue': green,
      if (blue != null) 'blueValue': blue,
      'hasPassword': requiresAuth,
      'uniqueId': uniqueId ?? cardId(),
      'tags': tags,
      if (note != null) 'note': note,
      if (points != null) 'pointsAmount': points,
    };
  }
}
