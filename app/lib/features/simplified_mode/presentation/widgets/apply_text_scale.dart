import 'package:app/features/simplified_mode/presentation/widgets/scaled_over_phone.dart';
import 'package:flutter/material.dart';

/// Lays the simplified mode's text size over the one the phone asks
/// for, so both are kept: the phone's size still moves the type.
Widget applyTextScale(BuildContext context, double factor, Widget child) {
  final MediaQueryData data = MediaQuery.of(context);
  return MediaQuery(
    data: data.copyWith(textScaler: ScaledOverPhone(data.textScaler, factor)),
    child: child,
  );
}
