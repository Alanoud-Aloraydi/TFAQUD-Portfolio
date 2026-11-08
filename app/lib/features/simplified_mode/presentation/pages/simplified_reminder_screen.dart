import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_done_screen.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What a full-screen reminder shows: its words, its picture, and its
/// answers.
class _ReminderContent {
  const _ReminderContent({
    required this.brand,
    required this.lead,
    required this.name,
    required this.line,
    required this.chips,
    required this.hero,
    required this.yesLabel,
    required this.onYes,
    this.onLater,
  });

  final String brand;
  final String lead;
  final String name;
  final String line;
  final List<String> chips;
  final Widget hero;
  final String yesLabel;
  final VoidCallback? onYes;

  /// Null for an appointment, which has nothing to put off.
  final VoidCallback? onLater;
}

/// The full-screen reminder a tapped notification opens, like a call: a
/// calm dark ground, one picture, and one or two big round answers.
class SimplifiedReminderScreen extends StatelessWidget {
  const SimplifiedReminderScreen({super.key, required this.kind});

  final TodayTaskKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimplifiedModeCubit, SimplifiedModeState>(
      builder: (context, state) {
        final SimplifiedDay? day = state.day;
        final TodaySchedule? schedule = state.schedule;
        final _ReminderContent? content = day == null || schedule == null
            ? null
            : switch (kind) {
                TodayTaskKind.medication => _dose(
                  context,
                  schedule.taskToRecord(kind),
                  day,
                  state.saving,
                ),
                TodayTaskKind.measurement => _measurement(
                  context,
                  schedule.taskToRecord(kind),
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
              child: content == null
                  ? const _NothingWaiting()
                  : _ReminderBody(content: content),
            ),
          ),
        );
      },
    );
  }

  _ReminderContent? _dose(
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

    return _ReminderContent(
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
      onLater: () => context.pushReplacement(
        Routes.simplifiedSnooze,
        extra: TodayTaskKind.medication,
      ),
    );
  }

  _ReminderContent? _measurement(
    BuildContext context,
    TodayTask? task,
    SimplifiedDay day,
  ) {
    if (task == null) return null;
    final MeasurementOccurrence item = task.measurement!;
    final bool bp = item.kind == MeasurementKind.bp;
    return _ReminderContent(
      brand: context.tr('simplified_mode.reminder_brand'),
      lead: context.tr('simplified_mode.time_for'),
      name: simplifiedMeasurementTitle(context, item.kind),
      line: bp
          ? context.tr('simplified_mode.bp_rest')
          : simplifiedTime(context, item.time),
      chips: <String>[
        if (bp) context.tr('simplified_mode.bp_arm'),
        for (final String code in item.conditions)
          context.tr('measurements.condition.$code'),
      ],
      hero: Icon(
        measurementIcon(item.kind),
        size: 80,
        color: SimplifiedStyle.accent,
      ),
      yesLabel: context.tr('simplified_mode.measure_now'),
      onYes: () => context.pushReplacement(
        Routes.simplifiedMeasure(day.circleId),
        extra: item.kind,
      ),
      onLater: () => context.pushReplacement(
        Routes.simplifiedSnooze,
        extra: TodayTaskKind.measurement,
      ),
    );
  }

  /// «تمام، علمت» only closes the reminder: nothing on the server records
  /// that it was seen.
  _ReminderContent? _appointment(
    BuildContext context,
    CareAppointment? appointment,
    DateTime now,
  ) {
    if (appointment == null) return null;
    final DateTime today = riyadhToday(now);
    final int daysAway = appointment.scheduledOn.difference(today).inDays;
    final String lead = switch (daysAway) {
      0 => context.tr('simplified_mode.appointment_today'),
      1 => context.tr('simplified_mode.appointment_tomorrow'),
      _ => context.tr('simplified_mode.appointment_coming'),
    };
    return _ReminderContent(
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

class _ReminderBody extends StatelessWidget {
  const _ReminderBody({required this.content});

  final _ReminderContent content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
              child: Column(
                children: <Widget>[
                  Text(
                    content.brand,
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.caption,
                      color: SimplifiedStyle.onDarkMuted,
                      weight: AppTextTheme.medium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      color: SimplifiedStyle.muted,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: SimplifiedStyle.attentionEdge,
                        width: 5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(child: content.hero),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    content.lead,
                    style: SimplifiedStyle.text(
                      28,
                      color: SimplifiedStyle.surface,
                    ),
                  ),
                  Text(
                    content.name,
                    textAlign: TextAlign.center,
                    style: SimplifiedStyle.head(
                      SimplifiedStyle.hero,
                      color: SimplifiedStyle.surface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content.line,
                    textAlign: TextAlign.center,
                    style: SimplifiedStyle.head(
                      SimplifiedStyle.headline,
                      color: SimplifiedStyle.surface,
                    ),
                  ),
                  if (content.chips.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        for (final String chip in content.chips)
                          SimplifiedChip(chip, onDark: true),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  ListenButton(
                    onDark: true,
                    segments: <String>[
                      content.lead,
                      content.name,
                      content.line,
                      ...content.chips,
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _RoundAnswer(
                        label: content.yesLabel,
                        icon: AppIcons.check,
                        fill: SimplifiedStyle.accent,
                        ink: SimplifiedStyle.ink,
                        onTap: content.onYes,
                      ),
                      if (content.onLater
                          case final VoidCallback later) ...<Widget>[
                        const SizedBox(width: 16),
                        _RoundAnswer(
                          label: context.tr('simplified_mode.remind_later'),
                          icon: AppIcons.clock,
                          fill: SimplifiedStyle.surface.withValues(alpha: .24),
                          ink: SimplifiedStyle.surface,
                          onTap: later,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAnswer extends StatelessWidget {
  const _RoundAnswer({
    required this.label,
    required this.icon,
    required this.fill,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        children: <Widget>[
          SizedBox(
            width: SimplifiedStyle.answer,
            height: SimplifiedStyle.answer,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: fill,
                foregroundColor: ink,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Semantics(
                label: label,
                excludeSemantics: true,
                child: Icon(icon, size: 46),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: SimplifiedStyle.head(21, color: SimplifiedStyle.surface),
            ),
          ),
        ],
      ),
    );
  }
}

/// The reminder's task is no longer waiting (someone in the family may
/// have recorded it), so there is nothing to answer.
class _NothingWaiting extends StatelessWidget {
  const _NothingWaiting();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.nothing_waiting'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(
              SimplifiedStyle.display,
              color: SimplifiedStyle.surface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('simplified_mode.nothing_waiting_text'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedStyle.onDarkMuted,
            ),
          ),
          const SizedBox(height: 32),
          SimplifiedButton(
            label: context.tr('simplified_mode.back_home'),
            tone: SimplifiedButtonTone.secondary,
            onPressed: () => context.go(Routes.simplifiedMode),
          ),
        ],
      ),
    );
  }
}
