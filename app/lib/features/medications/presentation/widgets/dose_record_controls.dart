import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/loading/loading_widget.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Defines the supported dose controls layout values.
enum DoseControlsLayout { regular, today, attention }

/// The answers to one unrecorded dose («انأخذت», another time, skip,
/// «ذكّرني لاحقًا»), or its recorded status. Calls the nearest
/// [MedicationOccurrencesCubit] and shows a refused answer's message.
class DoseRecordControls extends StatelessWidget {
  const DoseRecordControls({
    super.key,
    required this.occurrence,
    this.layout = DoseControlsLayout.regular,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final DoseControlsLayout layout;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final record = occurrence.record;
    if (record != null) {
      return _RecordedStatus(occurrence: occurrence, circleId: circleId);
    }
    final isRecording = context.select<MedicationOccurrencesCubit, bool>(
      (cubit) => cubit.state.recordingOccurrence == occurrence,
    );
    if (isRecording) return const _RecordingStatus();
    final today = PatientClockScope.of(context).today();
    final scheduledOn = scheduleDay(occurrence.scheduledOn);
    if (scheduledOn.isAfter(today)) return const SizedBox.shrink();
    final isToday = scheduledOn == today;
    if (layout != DoseControlsLayout.regular) {
      final height = layout == DoseControlsLayout.attention ? 34.0 : 44.0;
      final ButtonStyle compact = FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: Size(0, height),
      );
      final bool canSnooze = isToday && circleId != null;
      // The two answers first («انأخذت», «ذكّرني لاحقًا»), then the two
      // less common ones as text buttons, so no label wraps.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (isToday)
                Expanded(
                  // A day of four doses shows four «أُخذت» buttons. Read
                  // aloud they are the same word, so the reader cannot
                  // tell which medicine is being recorded: the label
                  // names it.
                  child: Semantics(
                    button: true,
                    label:
                        '${CareVoice.tr(context, circleId, 'medications.taken_short')}'
                        '، ${occurrence.name}',
                    excludeSemantics: true,
                    child: FilledButton.icon(
                      style: compact,
                      onPressed: () => _takeNow(context),
                      icon: const Icon(CupertinoIcons.checkmark, size: 16),
                      label: Text(
                        CareVoice.tr(
                          context,
                          circleId,
                          'medications.taken_short',
                        ),
                      ),
                    ),
                  ),
                ),
              if (isToday && canSnooze) const SizedBox(width: AppSpacing.sm),
              if (canSnooze)
                Expanded(
                  child: _SnoozeButton(
                    occurrence: occurrence,
                    circleId: circleId!,
                    style: compact,
                  ),
                ),
              if (!isToday)
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: compact,
                    onPressed: () => _takeAtDifferentTime(context),
                    icon: const Icon(CupertinoIcons.clock, size: 16),
                    label: Text(
                      CareVoice.tr(
                        context,
                        circleId,
                        'medications.different_time_short',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isToday)
                TextButton.icon(
                  onPressed: () => _takeAtDifferentTime(context),
                  icon: const Icon(CupertinoIcons.clock, size: 16),
                  label: Text(
                    CareVoice.tr(
                      context,
                      circleId,
                      'medications.different_time_short',
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: () => _skip(context),
                icon: const Icon(CupertinoIcons.minus_circle, size: 16),
                label: Text(context.tr('medications.skip_short')),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isToday) ...[
          FilledButton.icon(
            onPressed: () => _takeNow(context),
            icon: const Icon(CupertinoIcons.checkmark),
            label: Text(
              CareVoice.tr(context, circleId, 'medications.taken_now_action'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        OutlinedButton(
          onPressed: () => _takeAtDifferentTime(context),
          child: Text(context.tr('medications.different_time_action')),
        ),
        TextButton(
          onPressed: () => _skip(context),
          child: Text(context.tr('medications.skip_action')),
        ),
      ],
    );
  }

  Future<void> _takeNow(BuildContext context) async {
    final String? messageKey = await context
        .read<MedicationOccurrencesCubit>()
        .take(occurrence);
    if (context.mounted) _show(context, messageKey);
  }

  Future<void> _takeAtDifferentTime(BuildContext context) async {
    final takenAt = await selectTakenTime(
      context,
      occurrence.scheduledOn,
      circleId: circleId,
    );
    if (takenAt == null || !context.mounted) return;
    final String? messageKey = await context
        .read<MedicationOccurrencesCubit>()
        .take(occurrence, takenAt);
    if (context.mounted) _show(context, messageKey);
  }

  Future<void> _skip(BuildContext context) async {
    final draft = await selectSkippedDose(context);
    if (draft == null || !context.mounted) return;
    final String? messageKey = await context
        .read<MedicationOccurrencesCubit>()
        .record(occurrence, draft);
    if (context.mounted) _show(context, messageKey);
  }

  /// A refused answer's message ([messageKey]), wherever the controls are.
  /// [context] must still be mounted.
  void _show(BuildContext context, String? messageKey) {
    if (messageKey == null) return;
    AppToast.show(context, messageKey, kind: ToastKind.error);
  }
}

/// Renders the recording status element of dose record controls.
class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus();

  @override
  Widget build(BuildContext context) {
    final label = context.tr('medications.recording_dose');
    return Semantics(
      label: label,
      liveRegion: true,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingWidget(size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Renders the recorded status element of dose record controls.
class _RecordedStatus extends StatelessWidget {
  const _RecordedStatus({required this.occurrence, this.circleId});

  final DoseOccurrence occurrence;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final record = occurrence.record!;
    final taken = record.outcome == DoseOutcome.taken;
    // Care status map: taken is success; recorded as not taken is neutral,
    // never an error. The icon keeps its color; the word follows the
    // contrast setting.
    final Color iconColor = taken
        ? context.tokens.success
        : context.tokens.textSecondary;
    final Color ink = taken
        ? context.tokens.successText
        : context.tokens.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          Icon(
            taken
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.minus_circle,
            color: iconColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The patient reads «تم تسجيل إنك أخذت الجرعة»; someone
                // caring for them reads the patient's name instead.
                Text(
                  CareVoice.tr(
                    context,
                    circleId,
                    taken
                        ? occurrence.isTakenLate(PatientClockScope.of(context))
                              ? 'medications.taken_late_status'
                              : 'medications.taken_status'
                        : 'medications.skipped_status',
                  ),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: ink),
                ),
                if (record.takenAt case final takenAt?)
                  Text(
                    context.tr(
                      'medications.recorded_at',
                      args: [_takenTime(context, takenAt)],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (!taken && record.skipReasonCode != null)
                  Text(
                    context.tr(
                      'medications.skip_reason_line',
                      args: [doseSkipReasonText(context, record)],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (circleId case final circleId?)
                  if (record.recordedByName case final name?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PersonPhoto(
                          name: name,
                          photoPath: personPhotoPath(
                            circleId,
                            record.recordedByAccountId,
                          ),
                          avatarCode: record.recordedByAvatarCode,
                          size: AppSizes.iconSmall,
                        ),
                        const SizedBox(width: AppSpacing.tight),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _takenTime(BuildContext context, DateTime takenAt) {
    return wallTimeText(PatientClockScope.of(context).wallTime(takenAt));
  }
}

/// «ذكّرني لاحقًا»: the dose's own reminder again, as late as the person
/// slides the ruler of [showSnoozeSheet] (5 minutes a mark, up to 12 hours,
/// and never past halfway to the medicine's next dose), with the same
/// words as its notification. Once put off, the button says when it comes
/// («بنذكّرك 2:36 م»), and opens the ruler again. Put off by someone else
/// in the circle, it says until when and who («مؤجّلة إلى 2:36 م · لين»).
class _SnoozeButton extends StatefulWidget {
  const _SnoozeButton({
    required this.occurrence,
    required this.circleId,
    required this.style,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final ButtonStyle style;

  @override
  State<_SnoozeButton> createState() => _SnoozeButtonState();
}

class _SnoozeButtonState extends State<_SnoozeButton> {
  /// The reminders, where the app has them (a test of a card may not).
  DoseReminders? get _reminders =>
      GetIt.I.isRegistered<DoseReminders>() ? GetIt.I<DoseReminders>() : null;

  /// «ذكّرني لاحقًا»; «بنذكّرك 2:36 م» while this phone put the dose off
  /// ([at]); «مؤجّلة إلى 2:36 م · لين» while someone else did ([shared]).
  String _label(BuildContext context, DateTime? at, SharedSnooze? shared) {
    String clock(DateTime moment) =>
        wallTimeText(PatientClockScope.of(context).wallTime(moment));
    if (at != null) {
      return context.tr('reminders.snoozed', args: <String>[clock(at)]);
    }
    if (shared != null) {
      final String? name = shared.byName;
      return name == null
          ? context.tr(
              'reminders.snoozed_shared',
              args: <String>[clock(shared.remindAt)],
            )
          : context.tr(
              'reminders.snoozed_by',
              args: <String>[clock(shared.remindAt), name],
            );
    }
    return context.tr('reminders.snooze');
  }

  IconData _icon(DateTime? at, SharedSnooze? shared) =>
      at == null && shared == null
      ? CupertinoIcons.bell
      : CupertinoIcons.bell_fill;

  /// How long the dose may still be put off: 12 hours, and never past
  /// halfway to the next dose of the same medicine.
  Duration _limit(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    return doseSnoozeLimit(
      widget.occurrence,
      context.read<MedicationOccurrencesCubit>().state.occurrences,
      clock,
      DateTime.now().toUtc(),
    );
  }

  Future<void> _snooze() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Duration limit = _limit(context);
    if (limit.inMinutes < snoozeStepMinutes) {
      AppToast.showText(messenger, context.tr('reminders.snooze_none'));
      return;
    }
    final int? minutes = await showSnoozeSheet(
      context,
      limit: limit,
      clock: PatientClockScope.of(context),
    );
    if (!mounted) return;
    final DoseReminders? reminders = _reminders;
    if (minutes == null || reminders == null) return;
    await reminders.snoozeDose(
      widget.circleId,
      widget.occurrence,
      Duration(minutes: minutes),
    );
    if (!mounted) return;
    AppToast.showText(
      messenger,
      context.tr(
        'reminders.snoozed',
        args: <String>[afterDuration(context, minutes)],
      ),
    );
  }

  Widget _button(BuildContext context, DateTime? at, SharedSnooze? shared) =>
      FilledButton.tonalIcon(
        style: widget.style.copyWith(
          backgroundColor: const WidgetStatePropertyAll<Color>(
            AppSemanticColors.surfaceContent,
          ),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppSemanticColors.textPrimary,
          ),
        ),
        onPressed: _snooze,
        icon: Icon(_icon(at, shared), size: 16),
        label: Text(_label(context, at, shared)),
      );

  @override
  Widget build(BuildContext context) {
    // Put off by someone in the circle (the server's), while it waits; on
    // the patient's wall clock, as the rest of the card.
    final PatientClock clock = PatientClockScope.of(context);
    final SharedSnooze? shared = widget.occurrence.snooze;
    final SharedSnooze? waiting =
        shared != null && clock.wallTime(shared.remindAt).isAfter(clock.now())
        ? shared
        : null;
    final DoseReminders? reminders = _reminders;
    if (reminders == null) return _button(context, null, waiting);
    final String key = doseSnoozeKey(widget.circleId, widget.occurrence);
    return ValueListenableBuilder<Map<String, TaskSnooze>>(
      valueListenable: reminders.snoozes,
      builder: (BuildContext context, Map<String, TaskSnooze> snoozed, _) =>
          _button(context, snoozed[key]?.at, waiting),
    );
  }
}
