import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks how much later with the ruler of [showSnoozeSheet] (5 minutes a
/// mark, up to 12 hours, and never past halfway to the medicine's next
/// dose), then puts [occurrence] off that long and says so. Says
/// «ما فيه وقت» instead when less than one mark is left.
Future<void> requestDoseSnooze(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required String circleId,
  required DoseReminders? reminders,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final PatientClock clock = PatientClockScope.of(context);
  final Duration limit = doseSnoozeLimit(
    occurrence,
    context.read<MedicationOccurrencesCubit>().state.occurrences,
    clock,
    DateTime.now().toUtc(),
  );
  if (limit.inMinutes < snoozeStepMinutes) {
    AppToast.showText(messenger, context.tr('reminders.snooze_none'));
    return;
  }
  final int? minutes = await showSnoozeSheet(
    context,
    limit: limit,
    clock: clock,
  );
  if (!context.mounted) return;
  if (minutes == null || reminders == null) return;
  await reminders.snoozeDose(circleId, occurrence, Duration(minutes: minutes));
  if (!context.mounted) return;
  AppToast.showText(
    messenger,
    context.tr(
      'reminders.snoozed',
      args: <String>[afterDuration(context, minutes)],
    ),
  );
}
