import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
