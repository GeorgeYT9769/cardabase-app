import 'dart:io';

import 'package:cardabase/feature/cards/loyalty_card.dart';
import 'package:flutter/services.dart';

bool get canCreateCardWidget => Platform.isAndroid || Platform.isIOS;

Future<bool> createCardWidget(LoyaltyCard loyaltyCard) {
  const channel = MethodChannel('cardabase_widget');
  final color = loyaltyCard.color ?? LoyaltyCard.defaultColor;
  return channel.invokeMethod<bool>('setWidgetCard', {
    'data': loyaltyCard.barcode.data,
    'type': loyaltyCard.barcode.type,
    'r': (color.r * 255).toInt(),
    'g': (color.g * 255).toInt(),
    'b': (color.b * 255).toInt(),
  }).then((value) => value ?? false);
}
