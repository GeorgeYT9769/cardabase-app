// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final typeId = 0;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      lastSeenAppVersion: fields[0] as String?,
      autoBackups: fields[1] as AutoBackupSettings,
      theme: fields[2] as ThemeSettings,
      developerOptions: fields[3] as DeveloperOptions,
      useAutoBrightness: fields[4] as bool,
      vibrateOnDifferentActions: fields[5] as bool,
      tags: (fields[6] as List).cast<String>(),
      cardListViewOptions: fields[7] as CardListViewOptions,
      customExportPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.lastSeenAppVersion)
      ..writeByte(1)
      ..write(obj.autoBackups)
      ..writeByte(2)
      ..write(obj.theme)
      ..writeByte(3)
      ..write(obj.developerOptions)
      ..writeByte(4)
      ..write(obj.useAutoBrightness)
      ..writeByte(5)
      ..write(obj.vibrateOnDifferentActions)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.cardListViewOptions)
      ..writeByte(8)
      ..write(obj.customExportPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AutoBackupSettingsAdapter extends TypeAdapter<AutoBackupSettings> {
  @override
  final typeId = 1;

  @override
  AutoBackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AutoBackupSettings(
      isEnabled: fields[0] as bool,
      lastUpdate: fields[1] as DateTime?,
      interval: fields[2] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, AutoBackupSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.isEnabled)
      ..writeByte(1)
      ..write(obj.lastUpdate)
      ..writeByte(2)
      ..write(obj.interval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoBackupSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemeSettingsAdapter extends TypeAdapter<ThemeSettings> {
  @override
  final typeId = 2;

  @override
  ThemeSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeSettings(
      useDarkMode: fields[0] as bool,
      useExtraDark: fields[1] as bool,
      useSystemFont: fields[2] as bool,
      loyaltyCardEffect: fields[3] as LoyaltyCardEffectSettings,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.useDarkMode)
      ..writeByte(1)
      ..write(obj.useExtraDark)
      ..writeByte(2)
      ..write(obj.useSystemFont)
      ..writeByte(3)
      ..write(obj.loyaltyCardEffect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoyaltyCardEffectSettingsAdapter
    extends TypeAdapter<LoyaltyCardEffectSettings> {
  @override
  final typeId = 3;

  @override
  LoyaltyCardEffectSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoyaltyCardEffectSettings(
      isEnabled: fields[0] as bool,
      effect: fields[1] as LoyaltyCardEffect,
    );
  }

  @override
  void write(BinaryWriter writer, LoyaltyCardEffectSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.isEnabled)
      ..writeByte(1)
      ..write(obj.effect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyCardEffectSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeveloperOptionsAdapter extends TypeAdapter<DeveloperOptions> {
  @override
  final typeId = 5;

  @override
  DeveloperOptions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeveloperOptions(
      isEnabled: fields[0] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DeveloperOptions obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.isEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeveloperOptionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoyaltyCardEffectAdapter extends TypeAdapter<LoyaltyCardEffect> {
  @override
  final typeId = 4;

  @override
  LoyaltyCardEffect read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoyaltyCardEffect.snowy;
      case 1:
        return LoyaltyCardEffect.grain;
      case 2:
        return LoyaltyCardEffect.glitter;
      default:
        return LoyaltyCardEffect.snowy;
    }
  }

  @override
  void write(BinaryWriter writer, LoyaltyCardEffect obj) {
    switch (obj) {
      case LoyaltyCardEffect.snowy:
        writer.writeByte(0);
      case LoyaltyCardEffect.grain:
        writer.writeByte(1);
      case LoyaltyCardEffect.glitter:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyCardEffectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
