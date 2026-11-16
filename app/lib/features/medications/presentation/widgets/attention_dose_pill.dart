import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The pill beside a late dose. It is decoration; the name says what it is.
class AttentionDosePill extends StatelessWidget {
  const AttentionDosePill({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 17,
        backgroundColor: context.tokens.error.withValues(alpha: .08),
        child: Icon(
          TafaqodPhosphorIcons.pill,
          color: context.tokens.error,
          size: 18,
        ),
      ),
    );
  }
}
