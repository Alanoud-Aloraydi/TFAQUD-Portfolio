import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The end of the medication form: why it could not be saved ([errorKey]).
/// Stopping a medicine is not here: it is in the medicine's details on its
/// card, with the stop of a measurement plan and the cancel of a visit.
class MedicationFormFooter extends StatelessWidget {
  const MedicationFormFooter({super.key, this.errorKey});

  final String? errorKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (errorKey case final String error) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr(error),
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
    ],
  );
}
