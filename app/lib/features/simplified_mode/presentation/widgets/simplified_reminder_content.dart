import 'package:flutter/material.dart';

/// What a full-screen reminder shows: its words, its picture, and its
/// answers.
class SimplifiedReminderContent {
  const SimplifiedReminderContent({
    required this.brand,
    required this.lead,
    required this.name,
    required this.line,
    required this.chips,
    required this.hero,
    required this.yesLabel,
    required this.onYes,
    this.onLater,
  });

  final String brand;
  final String lead;
  final String name;
  final String line;
  final List<String> chips;
  final Widget hero;
  final String yesLabel;
  final VoidCallback? onYes;

  /// Null for an appointment, which has nothing to put off.
  final VoidCallback? onLater;
}
