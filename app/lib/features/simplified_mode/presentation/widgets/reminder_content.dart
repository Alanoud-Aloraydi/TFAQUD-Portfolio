import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_texts.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the reminder for [request] shows on [state]'s day: a dose's, a
/// reading's or a visit's. Null while the day is not read, and once its
/// task no longer waits (someone in the family may have recorded it).
SimplifiedReminderContent? reminderContent(
  BuildContext context,
  ReminderRequest request,
  SimplifiedModeState state,
) {
  final SimplifiedDay? day = state.day;
  final TodaySchedule? schedule = state.schedule;
  if (day == null || schedule == null) return null;
  final TodayTask? task = schedule.reminderTask(request, day.circleId);
  return switch (request.kind) {
    TodayTaskKind.medication => reminderDoseContent(
      context,
      task,
      day,
      saving: state.saving,
    ),
    TodayTaskKind.measurement => reminderMeasurementContent(context, task, day),
    TodayTaskKind.appointment => reminderAppointmentContent(
      context,
      reminderAppointment(request, day, schedule),
      day.circleId,
      now: state.now,
      saving: state.saving,
    ),
  };
}

/// The reminder of a reading: its kind's picture, how to take it, and
/// «تسجيل القياس الآن» or «ذكّرني لاحقًا». Null when [task] no longer
/// waits.
SimplifiedReminderContent? reminderMeasurementContent(
  BuildContext context,
  TodayTask? task,
  SimplifiedDay day,
) {
  if (task == null) return null;
  final MeasurementOccurrence item = task.measurement!;
  final bool bp = item.kind == MeasurementKind.bp;
  return SimplifiedReminderContent(
    lead: context.tr('simplified_mode.time_for'),
    name: simplifiedMeasurementTitle(context, item.kind),
    line: bp
        ? context.tr('simplified_mode.bp_rest')
        : simplifiedTime(context, item.time),
    chips: <String>[
      if (bp) context.tr('simplified_mode.bp_arm'),
      if (item.measurementState case final state?)
        context.tr('measurements.condition.$state'),
    ],
    hero: (double height) => SimplifiedReminderIconHero(
      icon: measurementIcon(item.kind),
      ground: CareVisuals.measurementTile,
      height: height,
    ),
    yesLabel: context.tr('simplified_mode.measure_now'),
    onYes: () => context.pushReplacement(
      Routes.simplifiedMeasure(day.circleId),
      extra: item,
    ),
    onLater: () =>
        unawaited(openSimplifiedSnooze(context, task, replace: true)),
  );
}

/// The reminder of a dose: the medicine's photo, what to take, and
/// «أخذته» or «ذكّرني لاحقًا». Null when [task] no longer waits.
SimplifiedReminderContent? reminderDoseContent(
  BuildContext context,
  TodayTask? task,
  SimplifiedDay day, {
  required bool saving,
}) {
  if (task == null) return null;
  final DoseOccurrence dose = task.dose!;
  Future<void> take() async {
    final DateTime? takenAt = await context
        .read<SimplifiedModeCubit>()
        .takeDose(dose);
    if (takenAt == null || !context.mounted) return;
    context.pushReplacement(
      Routes.simplifiedDone,
      extra: SimplifiedDoneMessage.doseTaken(dose.name, takenAt),
    );
  }

  return SimplifiedReminderContent(
    lead: context.tr('simplified_mode.time_for'),
    name: dose.name,
    line:
        '${simplifiedDoseAmount(context, dose)}، '
        '${simplifiedStrength(context, dose)}',
    chips: simplifiedTaskChips(context, task, day),
    hero: (double height) => MedicinePhoto(
      circleId: day.circleId,
      planId: dose.planId,
      height: height,
      radius: 0,
      iconSize: height * .45,
    ),
    yesLabel: context.tr('simplified_mode.took'),
    onYes: saving ? null : () => unawaited(take()),
    onLater: () =>
        unawaited(openSimplifiedSnooze(context, task, replace: true)),
  );
}

/// The reminder of a visit: when, with whom, and «حضرت» from an hour
/// before its time until it is missed (as «اليوم» does); otherwise it is
/// only read. Null when
/// [visit] no longer waits.
SimplifiedReminderContent? reminderAppointmentContent(
  BuildContext context,
  CareAppointment? visit,
  String circleId, {
  required DateTime now,
  required bool saving,
}) {
  if (visit == null) return null;
  final PatientClock clock = PatientClockScope.of(context);
  final String title = appointmentTitle(context, visit);
  final bool open = visit.canAttendAt(clock.wallTime(now), clock.today(now));
  return SimplifiedReminderContent(
    lead: simplifiedAppointmentLead(context, visit, clock.today(now)),
    name: title,
    line:
        '${appointmentDate(context, visit.scheduledOn)} '
        '${simplifiedTime(context, visit.time)}',
    people: visit.companions.isEmpty
        ? null
        : SimplifiedCompanions(
            circleId: circleId,
            companions: visit.companions,
            onDark: true,
          ),
    hero: (double height) => SimplifiedReminderIconHero(
      icon: appointmentKindIcon(visit.kind),
      ground: CareVisuals.appointmentTile,
      height: height,
    ),
    yesLabel: context.tr(
      open ? 'appointments.mark_completed' : 'simplified_mode.got_it',
    ),
    onYes: switch ((open, saving)) {
      (false, _) => () => context.pop(),
      (true, true) => null,
      (true, false) => () => unawaited(
        attendSimplifiedVisit(context, visit, title),
      ),
    },
  );
}

/// «حضرت» on [visit]: marks it attended, as the family's same button does
/// in the detailed mode, then says so on «تم، يعطيك العافية» with its
/// [title]. When it was not written, the screen stays and the mode's
/// message says why.
Future<void> attendSimplifiedVisit(
  BuildContext context,
  CareAppointment visit,
  String title,
) async {
  final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
  if (!await cubit.attendAppointment(visit) || !context.mounted) return;
  context.pushReplacement(
    Routes.simplifiedDone,
    extra: SimplifiedDoneMessage.visitAttended(title),
  );
}
