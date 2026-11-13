import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The title of the page of a person without the app, and one line on what
/// the circle is for. Nothing else is explained on the page.
class PatientFormHeader extends StatelessWidget {
  const PatientFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('circles.patient_title'),
          subtitle: context.tr('circles.patient_subtitle'),
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
