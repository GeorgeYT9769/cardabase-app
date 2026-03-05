import 'package:flutter/material.dart';

const int _asciiDigit0 = 48;
const int _asciiDigit9 = 57; // 48+9

FormFieldValidator<TIn> isNotEmpty<TIn>() {
  return (value) {
    if (value == null ||
        value == '' ||
        value is List && value.length == 0 ||
        value is Map && value.length == 0) {
      return 'Value cannot be empty';
    }
    return null;
  };
}

FormFieldValidator<TIn> hasLength<TIn>(int length) {
  return (value) {
    if (value == null ||
        value is String && value.length != length ||
        value is List && value.length != length ||
        value is Map && value.length != length) {
      return 'Value must have length $length';
    }
    return null;
  };
}

FormFieldValidator<String> isDigits() {
  return (value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (int i = 0; i < value.length; i++) {
      final char = value.codeUnitAt(i);
      if (char < _asciiDigit0 || char > _asciiDigit9) {
        return 'Value can only contain digits';
      }
    }
    return null;
  };
}

FormFieldValidator<String> hasValidGs1Checksum() {
  return (value) {
    if (value == null) {
      return null;
    }

    final length = value.length;
    if (length < 2) {
      return 'Value must have at least 2 digits';
    }

    var sum = 0;
    var multiplier = 3;

    for (var i = length - 2; i >= 0; i--) {
      final digit = value.codeUnitAt(i) - _asciiDigit0;

      sum += digit * multiplier;
      multiplier = (multiplier == 3) ? 1 : 3;
    }

    final checkDigit = value.codeUnitAt(length - 1) - _asciiDigit0;
    final calculated = (10 - (sum % 10)) % 10;

    if (checkDigit != calculated) {
      return 'Value is not valid. Did you mistype?';
    }
    return null;
  };
}

extension FormValidationExtensions<TIn> on FormFieldValidator<TIn> {
  FormFieldValidator<TIn> and(FormFieldValidator<TIn> other) {
    return (value) => this(value) ?? other(value);
  }
}
