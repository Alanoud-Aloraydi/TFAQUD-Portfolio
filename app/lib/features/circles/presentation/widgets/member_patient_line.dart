import 'package:app/core/theme/app_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The line under a patient's name on their card, which says whether they
/// use the app themselves.
class MemberPatientLine extends StatelessWidget {
  const MemberPatientLine({super.key, required this.usesApp});

  final bool usesApp;

  @override
  Widget build(BuildContext context) => Text(
    context.tr(
      usesApp
          ? 'circle_overview.patient_line'
          : 'circle_overview.patient_line_no_app',
    ),
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.tokens.textSecondary),
  );
}
