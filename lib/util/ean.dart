import 'dart:math';

VerifyEanException? verifyEan(int code, int length) {
  final maxValue = pow(10, length).toInt();
  if (code >= maxValue) {
    return const EanTooLongException();
  }

  final digits = List.filled(length, 0);
  // maths reads from right to left...
  var i = digits.length - 1;
  var leftOver = code ~/ 10;
  while (leftOver > 0) {
    digits[i] = leftOver % 10;
    leftOver = leftOver ~/ 10;
    i--;
  }

  final expectedCheckDigit = code % 10;

  var checkSum = 0;
  for (var i = 0; i < digits.length; i++) {
    final digit = digits[i];
    final multiplier = i % 2 == 0 ? 3 : 1;
    checkSum += digit * multiplier;
  }
  // var i = 0;
  // var divider = maxValue ~/ 10;
  //
  // // iterate over all digits except the last (last one is the expectedCheckDigit)
  // while (divider > 1) {
  //   final digit = code ~/ divider % 10;
  //   final multiplier = i % 2 == 0 ? 3 : 1;
  //   checkSum += digit * multiplier;
  //   divider = divider ~/ 10;
  //   i++;
  // }
  // expectedCheckDigit = code % 10;

  final checkDigit = (10 - checkSum % 10) % 10;
  if (checkDigit != expectedCheckDigit) {
    return const EanCheckSumIncorrectException();
  }

  return null;
}

sealed class VerifyEanException implements Exception {
  const VerifyEanException();
}

class EanTooLongException implements VerifyEanException {
  const EanTooLongException();
}

class EanCheckSumIncorrectException implements VerifyEanException {
  const EanCheckSumIncorrectException();
}
