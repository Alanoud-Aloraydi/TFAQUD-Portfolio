import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One version of a medicine in «سجل التعديلات»: the day it took over and
/// what the medicine was then, the schedule it replaced crossed out.
class MedicationRevisionEntry extends StatelessWidget {
  const MedicationRevisionEntry({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) => MedicationVersionCard(
    title: context.tr(
      previous == null
          ? 'medications.initial_version'
          : 'medications.revised_on',
      args: <String>[formatMedicationDate(context, version.effectiveFromOn)],
    ),
    version: version,
    previous: previous,
  );
}
