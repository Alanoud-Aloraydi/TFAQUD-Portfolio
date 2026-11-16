import 'package:flutter/material.dart';

/// A time of day as the API writes it, «HH:mm».
String formTimeText(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

/// A number as the field shows it: 500, not 500.0.
String formNumberText(double value) =>
    value.toString().replaceFirst(RegExp(r'\.0$'), '');

/// What was typed, or null when nothing but spaces was.
String? optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Whether [value] is a plain decimal number: digits, and at most one dot
/// with digits after it.
bool isDecimalText(String value) =>
    RegExp(r'^(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$').hasMatch(value);
