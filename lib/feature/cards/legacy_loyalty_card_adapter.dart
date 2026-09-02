import 'package:cardabase/data/unique_id.dart';
import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

/// Reads [LoyaltyCard] records that were written by older versions of the app.
///
/// The generated [LoyaltyCardAdapter] casts every non-nullable field
/// unconditionally, so a record that was written before a field was introduced
/// (e.g. `createdAt`/`lastModifiedAt`, added after `cards202603` shipped) makes
/// opening the box throw and the app never starts.
///
/// This adapter reads the same frame layout but falls back to the same defaults
/// the box migration uses. Writing is left to the generated adapter, so new
/// records always contain every field.
///
/// Keep the field numbers in sync with the `@HiveField` annotations on
/// [LoyaltyCard].
class LegacyLoyaltyCardAdapter extends LoyaltyCardAdapter {
  @override
  LoyaltyCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final now = DateTime.now().toUtc();
    return LoyaltyCard(
      id: fields[0] as String? ?? generateUniqueId(),
      barcode: fields[1] as Barcode? ?? const Barcode(data: '', type: null),
      name: fields[2] as String? ?? '',
      color: fields[3] as Color?,
      tags: (fields[4] as Set?)?.whereType<String>().toSet() ?? {},
      notes: fields[5] as String?,
      frontImagePath: fields[6] as String?,
      backImagePath: fields[7] as String?,
      useFrontImageOverlay: fields[8] as bool? ?? false,
      points: (fields[9] as num?)?.toInt() ?? 0,
      requiresAuth: fields[10] as bool? ?? false,
      hideName: fields[11] as bool? ?? false,
      createdAt: fields[12] as DateTime? ?? now,
      lastModifiedAt: fields[13] as DateTime? ?? fields[12] as DateTime? ?? now,
      usePoints: fields[14] as bool? ?? false,
    );
  }
}
