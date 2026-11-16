import 'package:flutter/material.dart';

/// The phone's own text size ([phone]) applied to text [factor] times
/// larger. Android 14+ grows large text less than small text at its big
/// sizes (a non-linear scaler); flattening it to one linear factor read at
/// size 1 would grow headings by the full factor and overflow them, so the
/// phone's curve is kept.
@visibleForTesting
class ScaledOverPhone extends TextScaler {
  const ScaledOverPhone(this.phone, this.factor);

  final TextScaler phone;
  final double factor;

  @override
  double scale(double fontSize) => phone.scale(fontSize * factor);

  @Deprecated('Use scale instead.')
  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is ScaledOverPhone &&
      other.phone == phone &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(phone, factor);
}
