import 'package:flutter/material.dart';

/// The three lines of a late dose, read as one: the medicine, the day and
/// time it was due, and the dose with how to take it.
class AttentionDoseText extends StatelessWidget {
  const AttentionDoseText({
    super.key,
    required this.title,
    required this.when,
    required this.how,
  });

  final String title;
  final String when;
  final String how;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleSmall),
        Text(when, style: text.bodySmall),
        Text(how, style: text.bodySmall),
      ],
    );
  }
}
