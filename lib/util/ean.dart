import 'package:equatable/equatable.dart';

VerifyEanException? verifyEan(String code, int length) {
  if (code.length != length) {
    return EanCodeInvalidLengthException();
  }

  var checkSum = 0;
  for (int i = 0; i < code.length - 1; i++) {
    final digit = int.parse(code[i]);
    final multiplier = i % 2 == 0 ? 1 : 3;
    checkSum += digit * multiplier;
  }
  final expectedCheckDigit = int.parse(code[code.length - 1]);

  final checkDigit = (10 - checkSum % 10) % 10;
  if (checkDigit != expectedCheckDigit) {
    return const EanCheckSumIncorrectException();
  }

  return null;
}

sealed class VerifyEanException implements Exception {
  const VerifyEanException();
}

final class EanCodeInvalidLengthException extends Equatable
    implements VerifyEanException {
  const EanCodeInvalidLengthException();

  @override
  List<Object?> get props => [];
}

final class EanCheckSumIncorrectException extends Equatable
    implements VerifyEanException {
  const EanCheckSumIncorrectException();

  @override
  List<Object?> get props => [];
}
