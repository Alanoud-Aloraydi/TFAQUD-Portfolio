import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows how the circle will be named for everyone, as the first name is
/// typed. Nobody names this circle.
class PatientCircleNameNote extends StatelessWidget {
  const PatientCircleNameNote({required this.firstName, super.key});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final String name = firstName.trim();
    final String shared = context.tr(
      'circles.shared_name',
      args: <String>[name],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsetText.header(context.tr('circles.circle_name')),
        const SizedBox(height: AppSpacing.sm),
        InsetText.note(
          name.isEmpty
              ? context.tr('circles.shared_name_hint')
              : context.tr('circles.name_preview', args: <String>[shared]),
        ),
      ],
    );
  }
}
