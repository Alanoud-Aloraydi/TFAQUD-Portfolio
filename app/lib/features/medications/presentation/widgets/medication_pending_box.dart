import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_version_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «تعديل مجدول» on a medicine's plan card, the same card as on its own
/// page: the day it takes over, what that means for the past doses, and
/// the medicine as [pending] will have it (the schedule of [current]
/// crossed out). Dropping it is on the medicine's page.
class MedicationPendingBox extends StatelessWidget {
  const MedicationPendingBox({
    super.key,
    required this.circleId,
    required this.current,
    required this.pending,
  });

  final String circleId;
  final MedicationVersion current;
  final MedicationVersion pending;

  @override
  Widget build(BuildContext context) => MedicationVersionCard(
    title: context.tr(
      'medications.pending_revision',
      args: <String>[formatMedicationDate(context, pending.effectiveFromOn)],
    ),
    note: CareVoice.tr(context, circleId, 'medications.effective_hint'),
    version: pending,
    previous: current,
  );
}
