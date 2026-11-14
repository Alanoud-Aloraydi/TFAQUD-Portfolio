import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_close_bar.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The full-screen reminder a tapped notification or a home card opens,
/// like a call: a calm dark ground, one picture, and one or two big round
/// answers.
class SimplifiedReminderScreen extends StatelessWidget {
  const SimplifiedReminderScreen({super.key, required this.request});

  /// The task it asks about; while it waits, it is shown live from the day.
  final ReminderRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimplifiedModeCubit, SimplifiedModeState>(
      builder: (context, state) {
        final SimplifiedDay? day = state.day;
        final TodaySchedule? schedule = state.schedule;
        final SimplifiedReminderContent? content =
            day == null || schedule == null
            ? null
            : switch (request.kind) {
                TodayTaskKind.medication => _dose(
                  context,
                  schedule.reminderTask(request, day.circleId),
                  day,
                  state.saving,
                ),
                TodayTaskKind.measurement => _measurement(
                  context,
                  schedule.reminderTask(request, day.circleId),
                  day,
                ),
                TodayTaskKind.appointment => _appointment(
                  context,
                  schedule.upcomingAppointment,
                  state.now,
                ),
              };
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: SimplifiedStyle.reminderGround,
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  const SimplifiedReminderCloseBar(),
                  Expanded(
                    child: content == null
                        ? const SimplifiedReminderNothingWaiting()
                        : SimplifiedReminderBody(content: content),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SimplifiedReminderContent? _dose(
    BuildContext context,
    TodayTask? task,
    SimplifiedDay day,
    bool saving,
  ) {
    if (task == null) return null;
    final dose = task.dose!;
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
      brand: context.tr('simplified_mode.reminder_brand'),
      lead: context.tr('simplified_mode.time_for'),
      name: dose.name,
      line:
          '${simplifiedDoseAmount(context, dose)} · '
          '${simplifiedStrength(context, dose)}',
      chips: <String>[
        if (dose.instructions case final String text
            when text.trim().isNotEmpty)
          text.trim(),
        ?day.reasons[dose.planId],
      ],
      hero: MedicinePhoto(
        circleId: day.circleId,
        planId: dose.planId,
        height: 176,
        width: 176,
        radius: 0,
        iconSize: 64,
      ),
      yesLabel: context.tr('simplified_mode.took'),
      onYes: saving ? null : () => unawaited(take()),
      onLater: () =>
          context.pushReplacement(Routes.simplifiedSnooze, extra: task),
    );
  }

  SimplifiedReminderContent? _measurement(
    BuildContext context,
    TodayTask? task,
    SimplifiedDay day,
  ) {
    if (task == null) return null;
    final MeasurementOccurrence item = task.measurement!;
    final bool bp = item.kind == MeasurementKind.bp;
    return SimplifiedReminderContent(
      brand: context.tr('simplified_mode.reminder_brand'),
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
      hero: Icon(
        measurementIcon(item.kind),
        size: 80,
        color: SimplifiedStyle.accent,
      ),
      yesLabel: context.tr('simplified_mode.measure_now'),
      onYes: () => context.pushReplacement(
        Routes.simplifiedMeasure(day.circleId),
        extra: item,
      ),
      onLater: () =>
          context.pushReplacement(Routes.simplifiedSnooze, extra: task),
    );
  }

  /// «تمام، علمت» only closes the reminder: nothing on the server records
  /// that it was seen.
  SimplifiedReminderContent? _appointment(
    BuildContext context,
    CareAppointment? appointment,
    DateTime now,
  ) {
    if (appointment == null) return null;
    // Calendar days, never 24-hour steps: on a phone whose own clocks
    // change, «غدًا» stays tomorrow.
    final DateTime today = PatientClockScope.of(context).today(now);
    final DateTime on = scheduleDay(appointment.scheduledOn);
    final String lead = context.tr(
      on == today
          ? 'simplified_mode.appointment_today'
          : on == addDays(today, 1)
          ? 'simplified_mode.appointment_tomorrow'
          : 'simplified_mode.appointment_coming',
    );
    return SimplifiedReminderContent(
      brand: context.tr('simplified_mode.appointment_brand'),
      lead: lead,
      name: appointmentTitle(context, appointment),
      line:
          '${appointmentDate(context, appointment.scheduledOn)} '
          '${simplifiedTime(context, appointment.time)}',
      chips: <String>[
        if (appointment.companions.isNotEmpty)
          context.tr(
            'simplified_mode.with_companions',
            args: <String>[appointmentCompanionNames(context, appointment)],
          ),
      ],
      hero: const Icon(
        AppIcons.calendar,
        size: 80,
        color: SimplifiedStyle.attentionEdge,
      ),
      yesLabel: context.tr('simplified_mode.got_it'),
      onYes: () => context.pop(),
    );
  }
}
