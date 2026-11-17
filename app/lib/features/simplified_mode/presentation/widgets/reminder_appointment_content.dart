import 'dart:async';

import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_icon.dart';
import 'package:app/features/simplified_mode/presentation/simplified_appointment_lead.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_attend_visit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_companions.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_icon_hero.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
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
