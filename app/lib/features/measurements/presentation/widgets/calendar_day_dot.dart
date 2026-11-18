import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// The dot under a calendar day that has readings: amber when any of them
/// is outside the target, green when all are inside.
class CalendarDayDot extends StatelessWidget {
  const CalendarDayDot({super.key, required this.outside});

  final bool outside;

  static const double _size = 5;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: outside
          ? AppSemanticColors.statusWarning
          : AppSemanticColors.statusSuccess,
    ),
  );
}
