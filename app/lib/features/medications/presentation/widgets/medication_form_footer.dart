import 'package:app/core/feedback/error_toast.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The end of the medication form. Why it could not be saved ([errorKey])
/// is a toast: a refusal of a field is said under that field. Stopping a
/// medicine is not here: it is in the medicine's details on its card, with
/// the stop of a measurement plan and the cancel of a visit.
class MedicationFormFooter extends StatelessWidget {
  const MedicationFormFooter({super.key, this.errorKey});

  final String? errorKey;

  @override
  Widget build(BuildContext context) => ErrorToast(
    errorKey: errorKey,
    child: const SizedBox(height: AppSpacing.xl),
  );
}
