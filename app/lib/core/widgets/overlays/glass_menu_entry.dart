import 'package:flutter/material.dart';

/// A row as the menu draws it, without its type.
class GlassMenuEntry {
  const GlassMenuEntry({
    required this.value,
    required this.label,
    this.icon,
    this.selected = false,
  });

  final Object? value;
  final String label;
  final IconData? icon;
  final bool selected;
}
