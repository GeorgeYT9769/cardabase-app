// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoyaltyCardAdapter extends TypeAdapter<LoyaltyCard> {
  @override
  final typeId = 8;

  @override
  LoyaltyCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoyaltyCard(
      id: fields[0] as String,
      barcode: fields[1] as Barcode,
      name: fields[2] as String,
      color: fields[3] as Color?,
      tags: (fields[4] as Set).cast<String>(),
      notes: fields[5] as String?,
      frontImagePath: fields[6] as String?,
      backImagePath: fields[7] as String?,
      useFrontImageOverlay: fields[8] as bool,
      points: (fields[9] as num).toInt(),
      requiresAuth: fields[10] as bool,
      hideName: fields[11] as bool,
      lastModifiedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LoyaltyCard obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barcode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.frontImagePath)
      ..writeByte(7)
      ..write(obj.backImagePath)
      ..writeByte(8)
      ..write(obj.useFrontImageOverlay)
      ..writeByte(9)
      ..write(obj.points)
      ..writeByte(10)
      ..write(obj.requiresAuth)
      ..writeByte(11)
      ..write(obj.hideName)
      ..writeByte(12)
      ..write(obj.lastModifiedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BarcodeAdapter extends TypeAdapter<Barcode> {
  @override
  final typeId = 9;

  @override
  Barcode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Barcode(
      data: fields[0] as String,
      type: fields[1] as BarcodeType,
    );
  }

  @override
  void write(BinaryWriter writer, Barcode obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.data)
      ..writeByte(1)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
