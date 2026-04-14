// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_list_view_options.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardListViewOptionsAdapter extends TypeAdapter<CardListViewOptions> {
  @override
  final typeId = 7;

  @override
  CardListViewOptions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardListViewOptions(
      numberOfColumns: (fields[0] as num).toInt(),
      sortingStyle: fields[1] as SortingStyle,
      customOrder: fields[2] == null ? [] : (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CardListViewOptions obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.numberOfColumns)
      ..writeByte(1)
      ..write(obj.sortingStyle)
      ..writeByte(2)
      ..write(obj.customOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardListViewOptionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SortingStyleAdapter extends TypeAdapter<SortingStyle> {
  @override
  final typeId = 6;

  @override
  SortingStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SortingStyle.nameAz;
      case 1:
        return SortingStyle.nameZa;
      case 2:
        return SortingStyle.latest;
      case 3:
        return SortingStyle.oldest;
      case 4:
        return SortingStyle.custom;
      default:
        return SortingStyle.nameAz;
    }
  }

  @override
  void write(BinaryWriter writer, SortingStyle obj) {
    switch (obj) {
      case SortingStyle.nameAz:
        writer.writeByte(0);
      case SortingStyle.nameZa:
        writer.writeByte(1);
      case SortingStyle.latest:
        writer.writeByte(2);
      case SortingStyle.oldest:
        writer.writeByte(3);
      case SortingStyle.custom:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortingStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
