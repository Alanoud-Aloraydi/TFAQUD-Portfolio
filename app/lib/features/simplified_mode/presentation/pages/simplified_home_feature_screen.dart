import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_home_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_home_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/listen_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measurement_sheet.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simplified mode's one home screen: the current task (due, missed, or
/// nothing left today), the family row, and the measurement/emergency
/// squares. See docs/the approved design brief for the three states.
class SimplifiedHomeFeatureScreen extends StatefulWidget {
  const SimplifiedHomeFeatureScreen({super.key});

  @override
  State<SimplifiedHomeFeatureScreen> createState() =>
      _SimplifiedHomeFeatureScreenState();
}

class _SimplifiedHomeFeatureScreenState
    extends State<SimplifiedHomeFeatureScreen>
    with WidgetsBindingObserver {
  final PhoneNotifications _phone = GetIt.I<PhoneNotifications>();
  StreamSubscription<String>? _taps;
  bool _remindersSynced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Opened by «ذكّرني لاحقًا» in a notification: set it again.
    final String? launch = _phone.takeLaunchTap();
    if (launch != null && isSnoozeTap(launch)) {
      unawaited(GetIt.I<DoseReminders>().snoozeTap(launch));
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
      unawaited(context.read<SimplifiedHomeCubit>().load());
      unawaited(GetIt.I<DoseReminders>().refresh());
    }
  }

  /// A reminder (a dose, a measurement, an appointment), or a snooze,
  /// reloads this screen: it already shows whichever task is due or missed,
  /// so no payload parsing is needed here.
  void _onTap(String payload) {
    if (!mounted) return;
    if (isSnoozeTap(payload)) {
      unawaited(GetIt.I<DoseReminders>().snoozeTap(payload));
      return;
    }
    if (reminderCircleId(payload) != null) {
      unawaited(context.read<SimplifiedHomeCubit>().load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimplifiedHomeCubit, SimplifiedHomeState>(
      builder: (context, state) {
        if (state.circleId case final circleId? when !_remindersSynced) {
          _remindersSynced = true;
          unawaited(
            GetIt.I<DoseReminders>().sync([
              ReminderCircle(id: circleId, name: state.greetingName ?? ''),
            ]),
          );
        }
        final Color background = switch (state.status) {
          SimplifiedHomeStatus.due => AppSemanticColors.textPrimary,
          SimplifiedHomeStatus.done => AppSemanticColors.statusSuccess,
          SimplifiedHomeStatus.missed => AppSemanticColors.background,
          SimplifiedHomeStatus.loading ||
          SimplifiedHomeStatus.error => AppSemanticColors.background,
        };
        return SimplifiedScale(
          child: Scaffold(
            backgroundColor: background,
            body: SafeArea(
              child: switch (state.status) {
                SimplifiedHomeStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                SimplifiedHomeStatus.error => Center(
                  child: TextButton(
                    onPressed: () => context.read<SimplifiedHomeCubit>().load(),
                    child: Text(context.tr('error.unknown')),
                  ),
                ),
                _ => _SimplifiedHomeBody(state: state),
              },
            ),
          ),
        );
      },
    );
  }
}

class _SimplifiedHomeBody extends StatelessWidget {
  const _SimplifiedHomeBody({required this.state});

  final SimplifiedHomeState state;

  List<String> _listenSegments(
    BuildContext context,
    SimplifiedHomeState state,
  ) {
    final String? name = state.greetingName;
    final String greeting = name == null
        ? ''
        : context.tr(
            state.greetingIsEvening
                ? 'simplified_mode.greeting_evening'
                : 'simplified_mode.greeting_morning',
            args: [name],
          );
    String status = '';
    final SimplifiedHomeTask? task = state.task;
    if (state.status == SimplifiedHomeStatus.done) {
      status = context.tr('simplified_mode.all_done');
    } else if (task != null) {
      final String label =
          task.label ??
          context.tr(
            task.measurementOccurrence?.kind == MeasurementKind.glucose
                ? 'measurements.glucose'
                : 'measurements.bp',
          );
      status = context.tr(
        state.status == SimplifiedHomeStatus.missed
            ? 'simplified_mode.missed_title'
            : 'simplified_mode.due_title',
        args: [label],
      );
    }
    return [
      greeting,
      status,
      if (task?.doseOccurrence != null &&
          state.status != SimplifiedHomeStatus.done) ...[
        context.tr('simplified_mode.dose_taken'),
        context.tr('simplified_mode.dose_later'),
      ],
      context.tr('simplified_mode.record_measurement'),
      context.tr('simplified_mode.emergency'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool onDark = state.status == SimplifiedHomeStatus.due;
    final Color foreground = onDark
        ? AppSemanticColors.surfaceContent
        : AppSemanticColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // In RTL, the leading edge is the right, so the photo (and
              // the greeting next to it) sit there and the listen button
              // is the one pushed to the far left.
              GestureDetector(
                onTap: () => context.push(Routes.simplifiedAccount),
                child: PersonPhoto(
                  name: state.greetingName ?? '',
                  photoPath: ApiEndpoints.accountPhoto,
                  size: 44,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (state.greetingName case final name?)
                Expanded(
                  child: Text(
                    context.tr(
                      state.greetingIsEvening
                          ? 'simplified_mode.greeting_evening'
                          : 'simplified_mode.greeting_morning',
                      args: [name],
                    ),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: foreground),
                  ),
                ),
              ListenButton(segments: _listenSegments(context, state)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      final MeasurementKind? kind =
                          state.task?.measurementOccurrence?.kind;
                      final String? circleId = state.circleId;
                      if (kind == null || circleId == null) return;
                      showSimplifiedMeasurementSheet(
                        context,
                        circleId: circleId,
                        lockedKind: kind,
                      );
                    },
                    child: _SimplifiedHomeTaskCard(
                      state: state,
                      onDark: onDark,
                    ),
                  ),
                  if (state.task?.doseOccurrence != null &&
                      state.status != SimplifiedHomeStatus.done) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _DoseActionButtons(onDark: onDark),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.members.where((m) => !m.isPatient).toList()
              case final family when family.isNotEmpty) ...[
            // Horizontally scrollable, never wrapped to more rows: a
            // circle with many members must not push the buttons below
            // out of reach.
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: family.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => _FamilyPhoto(
                  member: family[index],
                  circleId: state.circleId ?? '',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              Expanded(
                child: _SimplifiedHomeSquare(
                  label: context.tr('simplified_mode.record_measurement'),
                  icon: CupertinoIcons.drop,
                  color: AppSemanticColors.actionPrimary,
                  onTap: () {
                    final String? circleId = state.circleId;
                    if (circleId != null) {
                      showSimplifiedMeasurementSheet(
                        context,
                        circleId: circleId,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SimplifiedHomeSquare(
                  label: context.tr('simplified_mode.emergency'),
                  icon: CupertinoIcons.bandage,
                  color: AppSemanticColors.statusError,
                  onTap: () {
                    final String? circleId = state.circleId;
                    if (circleId != null) {
                      context.push(Routes.emergencyCard(circleId));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimplifiedHomeTaskCard extends StatelessWidget {
  const _SimplifiedHomeTaskCard({required this.state, required this.onDark});

  final SimplifiedHomeState state;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color foreground = onDark
        ? AppSemanticColors.surfaceContent
        : AppSemanticColors.textPrimary;
    if (state.status == SimplifiedHomeStatus.done) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 64,
            color: AppSemanticColors.surfaceContent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('simplified_mode.all_done'),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: AppSemanticColors.surfaceContent),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    final task = state.task;
    if (task == null) return const SizedBox.shrink();
    final String label = task.label ?? context.tr(_measurementLabel(task));
    final bool missed = state.status == SimplifiedHomeStatus.missed;
    return DecoratedBox(
      decoration: missed
          ? BoxDecoration(
              color: AppSemanticColors.surfaceAttention,
              border: Border.all(color: AppSemanticColors.borderAttention),
              borderRadius: BorderRadius.circular(AppRadius.l),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.all(missed ? AppSpacing.lg : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              missed
                  ? CupertinoIcons.exclamationmark_circle_fill
                  : CupertinoIcons.bell_fill,
              size: missed ? 48 : 64,
              color: missed ? AppSemanticColors.statusWarning : foreground,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              missed
                  ? context.tr('simplified_mode.missed_title', args: [label])
                  : context.tr('simplified_mode.due_title', args: [label]),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: foreground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr(
                missed
                    ? 'simplified_mode.missed_time'
                    : 'simplified_mode.due_time',
                args: [task.time],
              ),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: foreground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _measurementLabel(SimplifiedHomeTask task) {
    return task.measurementOccurrence?.kind == MeasurementKind.glucose
        ? 'measurements.glucose'
        : 'measurements.bp';
  }
}

class _DoseActionButtons extends StatefulWidget {
  const _DoseActionButtons({required this.onDark});

  final bool onDark;

  @override
  State<_DoseActionButtons> createState() => _DoseActionButtonsState();
}

class _DoseActionButtonsState extends State<_DoseActionButtons> {
  bool _busy = false;

  Future<void> _take(BuildContext context) async {
    setState(() => _busy = true);
    await context.read<SimplifiedHomeCubit>().takeDose();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _later(BuildContext context) async {
    final Duration? chosen = await showModalBottomSheet<Duration>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (label, minutes) in const [
              ('simplified_mode.later_15', 15),
              ('simplified_mode.later_30', 30),
              ('simplified_mode.later_60', 60),
            ])
              ListTile(
                title: Text(
                  sheetContext.tr(label),
                  textAlign: TextAlign.center,
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(Duration(minutes: minutes)),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      await context.read<SimplifiedHomeCubit>().snoozeDose(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground = widget.onDark
        ? AppSemanticColors.surfaceContent
        : AppSemanticColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: _busy ? null : () => _later(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            side: BorderSide(color: foreground),
          ),
          child: Text(context.tr('simplified_mode.dose_later')),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          onPressed: _busy ? null : () => _take(context),
          child: Text(context.tr('simplified_mode.dose_taken')),
        ),
      ],
    );
  }
}

class _SimplifiedHomeSquare extends StatelessWidget {
  const _SimplifiedHomeSquare({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.l),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppSemanticColors.surfaceContent, size: 32),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppSemanticColors.surfaceContent),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One family member's photo, with a small badge to call them when their
/// number is known.
class _FamilyPhoto extends StatelessWidget {
  const _FamilyPhoto({required this.member, required this.circleId});

  final CircleMember member;
  final String circleId;

  Future<void> _call() async {
    final String? phone = member.phoneNumber;
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    final photo = PersonPhoto(
      name: member.name,
      photoPath: ApiEndpoints.memberPhoto(circleId, member.accountId ?? ''),
      avatarCode: member.avatarCode,
      size: 68,
    );
    if (member.phoneNumber == null) return photo;
    return Semantics(
      button: true,
      label: context.tr('simplified_mode.call_member', args: [member.name]),
      child: GestureDetector(
        onTap: _call,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            photo,
            PositionedDirectional(
              bottom: -2,
              start: -2,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppSemanticColors.actionPrimary,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: AppSemanticColors.surfaceContent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(AppIcons.phoneCall, size: AppSizes.iconSmall),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
