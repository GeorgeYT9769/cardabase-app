import 'package:faker/faker.dart';

extension RandomExtensions on Faker {
  T? nullOr<T>(T Function() generator) {
    if (randomGenerator.boolean()) {
      return null;
    }
    return generator();
  }

  /// A string of [length] digits, which is what most barcodes are made of.
  String digits(int length) {
    return randomGenerator.numbers(10, length).join();
  }

  /// A string of [length] characters, each taken from [alphabet].
  String stringFrom(String alphabet, int length) {
    return List.generate(
      length,
      (_) => alphabet[randomGenerator.integer(alphabet.length)],
    ).join();
  }
}
