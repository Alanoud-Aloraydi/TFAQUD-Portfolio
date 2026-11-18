/// One reason of a [showSkipReasonSheet]: its API code and its words.
class SkipReasonOption {
  const SkipReasonOption(this.code, this.label);

  final String code;
  final String label;
}

/// What the person chose: the reason's code (null for none) and, for
/// «سبب آخر» (`other`), what they typed.
typedef SkipReasonChoice = ({String? code, String? note});
