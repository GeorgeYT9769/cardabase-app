int gs1CheckDigit(String digits) {
  var sum = 0;
  var multiplier = 3;
  for (var i = digits.length - 1; i >= 0; i--) {
    sum += int.parse(digits[i]) * multiplier;
    multiplier = multiplier == 3 ? 1 : 3;
  }
  return (10 - (sum % 10)) % 10;
}
