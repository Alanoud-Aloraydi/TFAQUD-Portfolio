import 'package:flutter/material.dart';

/// What a full-screen reminder shows: its words, its picture, and its
/// answers.
class SimplifiedReminderContent {
  const SimplifiedReminderContent({
    required this.lead,
    required this.name,
    required this.line,
    required this.hero,
    required this.yesLabel,
    required this.onYes,
    this.chips = const <String>[],
    this.people,
    this.onLater,
  });

  final String lead;
  final String name;
  final String line;
  final List<String> chips;

  /// The picture, filling a frame of the height given: the screen decides
  /// how tall it can be.
  final Widget Function(double height) hero;

  /// Who comes along to a visit, each one's photo before their name.
  final Widget? people;
  final String yesLabel;
  final VoidCallback? onYes;

  /// Null for an appointment, which has nothing to put off.
  final VoidCallback? onLater;
}
