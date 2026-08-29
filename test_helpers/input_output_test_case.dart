class InputOutputTestCase<TIn, TOut> {
  const InputOutputTestCase({
    required this.name,
    required this.input,
    required this.expected,
  });

  final String name;
  final TIn input;
  final TOut expected;
}
