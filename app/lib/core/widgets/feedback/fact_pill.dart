import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:flutter/material.dart';

/// A plain fact in a small soft pill — a strength, a dose, a time, how
/// often: the shape of a status, in the calm colour of a fact.
class FactPill extends StatelessWidget {
  const FactPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => StatusPill(
    text: text,
    background: AppSemanticColors.selectedSurface,
    foreground: AppSemanticColors.textPrimary,
  );
}
