import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
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
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// The simplified mode's home: a greeting, one card for what matters now
/// (the next task, a missed dose, or a finished day), the day's list, the
/// family to call, and the two squares (a reading, the emergency card).
class SimplifiedModeFeatureScreen extends StatefulWidget {
  const SimplifiedModeFeatureScreen({super.key});

  @override
  State<SimplifiedModeFeatureScreen> createState() =>
      _SimplifiedModeFeatureScreenState();
}

class _SimplifiedModeFeatureScreenState
    extends State<SimplifiedModeFeatureScreen>
    with WidgetsBindingObserver {
  final PhoneNotifications _phone = GetIt.I<PhoneNotifications>();
  StreamSubscription<String>? _taps;

  /// A reminder tapped before the day was read; opened once it is.
  TodayTaskKind? _pendingReminder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final String? launchTap = _phone.takeLaunchTap();
    if (launchTap != null) {
      // Opened by «ذكّرني لاحقًا» in a notification: put it off again, and
      // open nothing.
      if (isSnoozeTap(launchTap)) {
        unawaited(
          context.read<SimplifiedModeCubit>().snoozeFromNotification(launchTap),
        );
      } else {
        _pendingReminder = reminderTaskKind(launchTap);
      }
    }
    _taps = _phone.taps.listen(_onTap);
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<SimplifiedModeCubit>().resumed());
    }
  }

  /// A reminder reads the day again (it may have changed since), then
  /// opens its full-screen reminder over whatever is on screen.
  Future<void> _onTap(String payload) async {
    if (!mounted) return;
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    if (isSnoozeTap(payload)) {
      await cubit.snoozeFromNotification(payload);
      return;
    }
    final TodayTaskKind? kind = reminderTaskKind(payload);
    if (kind == null) return;
    await cubit.load();
    if (!mounted || cubit.state.day == null) return;
    unawaited(context.push(Routes.simplifiedReminder, extra: kind));
  }

  void _openPending(BuildContext context) {
    final TodayTaskKind? kind = _pendingReminder;
    if (kind == null) return;
    _pendingReminder = null;
    unawaited(context.push(Routes.simplifiedReminder, extra: kind));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimplifiedModeCubit, SimplifiedModeState>(
      listenWhen: (before, after) =>
          (after.day != null && before.day == null) ||
          (after.messageKey != null && after.messageKey != before.messageKey),
      listener: (context, state) {
        if (state.day != null) _openPending(context);
        final String? key = state.messageKey;
        if (key != null && state.status == SimplifiedModeStatus.ready) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.tr(key))));
          context.read<SimplifiedModeCubit>().messageShown();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: SimplifiedStyle.canvas,
          body: SafeArea(
            child: switch ((state.status, state.day, state.schedule)) {
              (_, final SimplifiedDay day, final TodaySchedule schedule) =>
                RefreshIndicator(
                  onRefresh: context.read<SimplifiedModeCubit>().load,
                  child: _HomeBody(
                    day: day,
                    schedule: schedule,
                    now: state.now,
                  ),
                ),
              (SimplifiedModeStatus.failure, _, _) => _LoadFailed(
                messageKey: state.messageKey,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        );
      },
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.messageKey});

  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SimplifiedStyle.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.tr(messageKey ?? 'error.unknown'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedStyle.ink,
            ),
          ),
          const SizedBox(height: SimplifiedStyle.gap),
          SimplifiedButton(
            label: context.tr('simplified_mode.try_again'),
            onPressed: context.read<SimplifiedModeCubit>().load,
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.day,
    required this.schedule,
    required this.now,
  });

  final SimplifiedDay day;
  final TodaySchedule schedule;
  final DateTime now;

  List<String> _listen(BuildContext context) => <String>[
    simplifiedGreeting(context, day.displayName, now, day.prayers),
    simplifiedToday(context, now),
    ..._focusSpeech(context),
    context.tr(
      'simplified_mode.schedule_summary',
      args: <String>['${schedule.doneCount}', '${schedule.total}'],
    ),
    context.tr('simplified_mode.record_measurement'),
    context.tr('simplified_mode.emergency'),
  ];

  List<String> _focusSpeech(BuildContext context) {
    final TodayTask? task = schedule.focusTask;
    return switch (schedule.focus) {
      HomeFocus.lateDose => <String>[
        context.tr('simplified_mode.late_question'),
        simplifiedTaskTitle(context, task!),
        context.tr(
          'simplified_mode.was_due',
          args: <String>[simplifiedTime(context, task.time)],
        ),
      ],
      HomeFocus.task => <String>[
        simplifiedTaskTitle(context, task!),
        simplifiedTime(context, task.time),
      ],
      HomeFocus.allDone => <String>[context.tr('simplified_mode.all_done')],
      HomeFocus.empty => <String>[context.tr('simplified_mode.nothing_today')],
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        8,
        SimplifiedStyle.page,
        28,
      ),
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            button: true,
            label: context.tr('simplified_mode.account_title'),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(Routes.simplifiedAccount),
              child: PersonPhoto(
                name: day.displayName ?? '',
                photoPath: ApiEndpoints.accountPhoto,
                avatarCode: day.avatarCode,
                size: SimplifiedStyle.touch,
              ),
            ),
          ),
        ),
        const SizedBox(height: SimplifiedStyle.gap),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 12,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  simplifiedGreeting(
                    context,
                    day.displayName,
                    now,
                    day.prayers,
                  ),
                  style: SimplifiedStyle.head(SimplifiedStyle.display),
                ),
                const SizedBox(height: 6),
                Text(
                  simplifiedToday(context, now),
                  style: SimplifiedStyle.text(
                    SimplifiedStyle.body,
                    weight: AppTextTheme.medium,
                  ),
                ),
              ],
            ),
            ListenButton(segments: _listen(context)),
          ],
        ),
        const SizedBox(height: SimplifiedStyle.pad),
        switch (schedule.focus) {
          HomeFocus.lateDose => _LateDoseCard(
            task: schedule.focusTask!,
            day: day,
          ),
          HomeFocus.task => _NextCard(
            task: schedule.focusTask!,
            day: day,
            schedule: schedule,
            now: now,
          ),
          HomeFocus.allDone => _DoneCard(schedule: schedule),
          HomeFocus.empty => const _EmptyCard(),
        },
        const SizedBox(height: SimplifiedStyle.gap),
        _ScheduleLink(schedule: schedule),
        if (day.family.isNotEmpty) ...<Widget>[
          const SizedBox(height: SimplifiedStyle.gap),
          _FamilyCard(family: day.family, circleId: day.circleId),
        ],
        const SizedBox(height: SimplifiedStyle.gap),
        _Squares(circleId: day.circleId),
      ],
    );
  }
}

/// Opens the full-screen reminder of [task] when it can be recorded now;
/// a measurement goes straight to its reading.
void _openTask(BuildContext context, TodayTask task, String circleId) {
  if (task.kind == TodayTaskKind.measurement) {
    unawaited(
      context.push(
        Routes.simplifiedMeasure(circleId),
        extra: task.measurement!.kind,
      ),
    );
    return;
  }
  unawaited(context.push(Routes.simplifiedReminder, extra: task.kind));
}

/// The next task: the medicine's photo first (how the patient knows it),
/// then the time, the name and what to take.
class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.task,
    required this.day,
    required this.schedule,
    required this.now,
  });

  final TodayTask task;
  final SimplifiedDay day;
  final TodaySchedule schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bool recordable =
        task.kind != TodayTaskKind.appointment && schedule.canRecord(task);
    final PrayerPeriod? period = day.prayers == null
        ? null
        : prayerPeriodOf(task.time, day.prayers!);
    final String when = task.status == TodayTaskStatus.late
        ? context.tr('simplified_mode.status.late')
        : context.tr(
            'simplified_mode.next_in',
            args: <String>[simplifiedUntil(context, task.scheduledAt, now)],
          );
    return SimplifiedCard(
      padding: EdgeInsets.zero,
      side: const BorderSide(color: SimplifiedStyle.ink, width: 2),
      onTap: recordable ? () => _openTask(context, task, day.circleId) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              _hero(),
              if (period != null)
                PositionedDirectional(
                  top: 14,
                  start: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: SimplifiedStyle.surface,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      simplifiedPeriod(context, period),
                      style: SimplifiedStyle.head(SimplifiedStyle.caption),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(SimplifiedStyle.pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  when,
                  style: SimplifiedStyle.label(
                    SimplifiedStyle.caption,
                    color: task.status == TodayTaskStatus.late
                        ? SimplifiedStyle.attentionInk
                        : SimplifiedStyle.muted,
                  ),
                ),
                Text(
                  simplifiedTime(context, task.time),
                  style: SimplifiedStyle.head(
                    SimplifiedStyle.time,
                    height: 1.1,
                  ),
                ),
                const Divider(height: 28, color: SimplifiedStyle.line),
                Text(
                  simplifiedTaskTitle(context, task),
                  style: SimplifiedStyle.head(SimplifiedStyle.name),
                ),
                ..._details(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    if (task.kind == TodayTaskKind.medication) {
      return MedicinePhoto(
        circleId: day.circleId,
        planId: task.dose!.planId,
        height: 210,
        radius: 0,
        iconSize: 96,
      );
    }
    final bool measurement = task.kind == TodayTaskKind.measurement;
    return Container(
      height: 150,
      width: double.infinity,
      color: measurement
          ? CareVisuals.measurementTile
          : CareVisuals.appointmentTile,
      child: Icon(
        measurement
            ? measurementIcon(task.measurement!.kind)
            : CareVisuals.appointmentIcon,
        size: 80,
        color: AppSemanticColors.onSettingsTile,
      ),
    );
  }

  List<Widget> _details(BuildContext context) {
    final List<String> chips = _taskChips(context, task, day);
    return <Widget>[
      if (task.dose case final dose?) ...<Widget>[
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          children: <Widget>[
            Text(
              simplifiedDoseAmount(context, dose),
              style: SimplifiedStyle.head(SimplifiedStyle.headline),
            ),
            Text(
              simplifiedStrength(context, dose),
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                weight: AppTextTheme.medium,
              ),
            ),
          ],
        ),
      ],
      if (chips.isNotEmpty) ...<Widget>[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String chip in chips) SimplifiedChip(chip),
          ],
        ),
      ],
    ];
  }
}

/// The short notes of a task: a dose's instructions and the medicine's
/// reason, a glucose task's context, an appointment's companions.
List<String> _taskChips(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
) {
  return switch (task.kind) {
    TodayTaskKind.medication => <String>[
      if (task.dose!.instructions case final String text
          when text.trim().isNotEmpty)
        text.trim(),
      ?day.reasons[task.dose!.planId],
    ],
    TodayTaskKind.measurement => <String>[
      for (final String code in task.measurement!.conditions)
        context.tr('measurements.condition.$code'),
    ],
    TodayTaskKind.appointment => <String>[
      if (task.appointment!.companions.isNotEmpty)
        context.tr(
          'simplified_mode.with_companions',
          args: <String>[
            task.appointment!.companions
                .map((companion) => companion.name)
                .join(context.tr('appointments.companion_separator')),
          ],
        ),
    ],
  };
}

/// A dose whose time passed unrecorded: ask, and offer to record it now.
class _LateDoseCard extends StatelessWidget {
  const _LateDoseCard({required this.task, required this.day});

  final TodayTask task;
  final SimplifiedDay day;

  Future<void> _take(BuildContext context) async {
    final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
    final DateTime? takenAt = await cubit.takeDose(task.dose!);
    if (takenAt == null || !context.mounted) return;
    unawaited(
      context.push(
        Routes.simplifiedDone,
        extra: SimplifiedDoneMessage.doseTaken(task.dose!.name, takenAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = context.select<SimplifiedModeCubit, bool>(
      (cubit) => cubit.state.saving,
    );
    final List<String> chips = _taskChips(context, task, day);
    return SimplifiedCard(
      color: SimplifiedStyle.attention,
      side: const BorderSide(color: SimplifiedStyle.attentionEdge, width: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 24,
      ),
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.late_question'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
          const SizedBox(height: 12),
          MedicinePhoto(
            circleId: day.circleId,
            planId: task.dose!.planId,
            height: 124,
            width: 124,
            radius: 30,
            iconSize: 48,
          ),
          const SizedBox(height: 12),
          Text(
            task.dose!.name,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(SimplifiedStyle.name),
          ),
          Text(
            simplifiedDoseAmount(context, task.dose!),
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
          Text(
            simplifiedStrength(context, task.dose!),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
          if (chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final String chip in chips) SimplifiedChip(chip),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            context.tr(
              'simplified_mode.was_due',
              args: <String>[simplifiedTime(context, task.time)],
            ),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedStyle.attentionInk,
              weight: AppTextTheme.bold,
            ),
          ),
          const SizedBox(height: 16),
          SimplifiedButton(
            label: context.tr('simplified_mode.took_now'),
            icon: AppIcons.check,
            onPressed: saving ? null : () => _take(context),
          ),
          const SizedBox(height: 12),
          SimplifiedButton(
            label: context.tr('simplified_mode.remind_later'),
            tone: SimplifiedButtonTone.secondary,
            onPressed: () => context.push(
              Routes.simplifiedSnooze,
              extra: TodayTaskKind.medication,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    final String count = context.tr(
      'simplified_mode.done_count',
      args: <String>['${schedule.doneCount}', '${schedule.total}'],
    );
    final String? tomorrow = switch (schedule.firstDoseTomorrow) {
      final dose? => context.tr(
        'simplified_mode.first_dose_tomorrow',
        args: <String>[simplifiedTime(context, dose.time)],
      ),
      null => null,
    };
    return SimplifiedCard(
      child: Column(
        children: <Widget>[
          const CircleAvatar(
            radius: 36,
            backgroundColor: SimplifiedStyle.accentTint,
            child: Icon(
              AppIcons.check,
              size: 40,
              color: SimplifiedStyle.success,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('simplified_mode.all_done'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(26),
          ),
          const SizedBox(height: 6),
          Text(
            tomorrow == null ? count : '$count · $tomorrow',
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      child: Text(
        context.tr('simplified_mode.nothing_today'),
        textAlign: TextAlign.center,
        style: SimplifiedStyle.head(SimplifiedStyle.headline),
      ),
    );
  }
}

class _ScheduleLink extends StatelessWidget {
  const _ScheduleLink({required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 18,
      ),
      onTap: () => context.push(Routes.simplifiedSchedule),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.tr('simplified_mode.schedule_title'),
                  style: SimplifiedStyle.head(SimplifiedStyle.title),
                ),
                Text(
                  context.tr(
                    'simplified_mode.schedule_summary',
                    args: <String>[
                      '${schedule.doneCount}',
                      '${schedule.total}',
                    ],
                  ),
                  style: SimplifiedStyle.text(SimplifiedStyle.caption),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.next, size: 28, color: SimplifiedStyle.ink),
        ],
      ),
    );
  }
}

/// The family to call, one tap each. More than three scroll sideways,
/// never into more rows, so the squares below stay in reach.
class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family, required this.circleId});

  final List<CircleMember> family;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final bool many = family.length > 3;
    return SimplifiedCard(
      padding: const EdgeInsets.all(SimplifiedStyle.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr(
              many
                  ? 'simplified_mode.family_title_swipe'
                  : 'simplified_mode.family_title',
            ),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final CircleMember member in family)
                  _FamilyMember(member: member, circleId: circleId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyMember extends StatelessWidget {
  const _FamilyMember({required this.member, required this.circleId});

  final CircleMember member;
  final String circleId;

  Future<void> _call() async {
    final String? phone = member.phoneNumber;
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        'simplified_mode.call_member',
        args: <String>[member.name],
      ),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
        onTap: _call,
        child: SizedBox(
          width: 88,
          child: Column(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  PersonPhoto(
                    name: member.name,
                    photoPath: ApiEndpoints.memberPhoto(
                      circleId,
                      member.accountId ?? '',
                    ),
                    avatarCode: member.avatarCode,
                    size: 72,
                  ),
                  PositionedDirectional(
                    bottom: -2,
                    end: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SimplifiedStyle.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SimplifiedStyle.surface,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        AppIcons.phoneCall,
                        size: 14,
                        color: SimplifiedStyle.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                member.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SimplifiedStyle.head(SimplifiedStyle.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Squares extends StatelessWidget {
  const _Squares({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _Square(
              dark: true,
              icon: CareVisuals.measurementIcon,
              iconColor: CareVisuals.measurementTile,
              title: context.tr('simplified_mode.record_measurement'),
              subtitle: context.tr('simplified_mode.record_measurement_sub'),
              onTap: () => context.push(Routes.simplifiedMeasure(circleId)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Square(
              icon: AppIcons.firstAid,
              iconColor: SimplifiedStyle.danger,
              title: context.tr('simplified_mode.emergency'),
              subtitle: context.tr('simplified_mode.emergency_sub'),
              onTap: () =>
                  context.push(Routes.simplifiedEmergencyCard(circleId)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      color: dark ? SimplifiedStyle.ink : SimplifiedStyle.surface,
      side: dark
          ? BorderSide.none
          : const BorderSide(color: SimplifiedStyle.line),
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: SimplifiedStyle.head(
                SimplifiedStyle.body,
                color: dark ? SimplifiedStyle.surface : SimplifiedStyle.ink,
              ),
            ),
            Text(
              subtitle,
              style: SimplifiedStyle.text(
                SimplifiedStyle.caption,
                color: dark
                    ? SimplifiedStyle.onDarkMuted
                    : SimplifiedStyle.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
