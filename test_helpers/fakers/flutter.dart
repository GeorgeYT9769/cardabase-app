import 'dart:ui';

import 'package:faker/faker.dart' hide Color;

extension FlutterFakerExtensions on Faker {
  FlutterFaker flutter() => FlutterFaker(this);
}

class FlutterFaker {
  const FlutterFaker(this.faker);

  final Faker faker;

  Color color() {
    return Color(faker.randomGenerator.integer(0xFFFFFFFF, min: 0));
  }

  /// A path to a file which was picked or taken on the device. Nothing is
  /// written there: the tests which use one never read it back.
  String filePath({String extension = 'png'}) {
    return '/storage/emulated/0/Android/data/cardabase/files/'
        '${faker.guid.guid()}.$extension';
  }

  /// A moment in time, in utc, which is how the app stores its timestamps.
  DateTime utcDateTime({int minYear = 2024, int maxYear = 2026}) {
    return faker.date.dateTime(minYear: minYear, maxYear: maxYear).toUtc();
  }
}
