VerifyEanException? verifyEan(int code, int length) {
  final maxValue = int.parse(''.padLeft(length, '9'));
  if (code > maxValue) {
    return const EanTooLongException();
  }

  var checkSum = 0;
  var expectedCheckDigit = 0;

  expectedCheckDigit = code % 10;
  var leftOver = code ~/ 10;
  while (leftOver > 0) {
    final digit = leftOver % 10;
    final multiplier = digit % 2 == 0 ? 3 : 1;
    checkSum += digit * multiplier;
    leftOver = leftOver ~/ 10;
  }

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
