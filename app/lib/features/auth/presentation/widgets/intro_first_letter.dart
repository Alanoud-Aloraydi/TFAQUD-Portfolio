import 'package:flutter/material.dart';

/// The first letter of a name, for its round letter.
String firstLetter(String name) {
  final String trimmed = name.trim();
  return trimmed.isEmpty ? '' : trimmed.characters.first;
}
