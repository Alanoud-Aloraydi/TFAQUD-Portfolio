import 'package:flutter/material.dart';

/// A small grey label over its value.
class EmergencyLine extends StatelessWidget {
  const EmergencyLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.bodySmall),
        Text(value, style: text.titleMedium),
      ],
    );
  }
}
