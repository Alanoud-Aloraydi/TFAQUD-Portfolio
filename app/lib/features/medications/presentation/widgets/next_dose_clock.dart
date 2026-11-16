import 'package:app/core/l10n/arabic_names.dart';
import 'package:flutter/material.dart';

/// A dose's time, large: the hour and minutes on one line and «ص» or «م»
/// under them, so the number itself reads from across the room.
class NextDoseClock extends StatelessWidget {
  const NextDoseClock({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> parts = clockText(time).split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(parts.first, style: text.displaySmall),
        if (parts.length > 1) Text(parts.last, style: text.labelMedium),
      ],
    );
  }
}
