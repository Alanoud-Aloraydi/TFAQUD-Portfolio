import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/widgets/loading/loading_widget.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/dose_reminder_texts.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Defines the supported dose controls layout values.
enum DoseControlsLayout { regular, today, attention }

/// Displays the dose record controls UI.
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
    final today = riyadhToday();
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

  Future<void> _takeNow(BuildContext context) =>
      _recordTaken(context, DateTime.now());

  Future<void> _takeAtDifferentTime(BuildContext context) async {
    final takenAt = await selectTakenTime(
      context,
      occurrence.scheduledOn,
      circleId: circleId,
    );
    if (takenAt == null || !context.mounted) return;
    if (takenAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('medications.future_taken_time'))),
      );
      return;
    }
    await _recordTaken(context, takenAt);
  }

  Future<void> _recordTaken(BuildContext context, DateTime takenAt) async {
    await context.read<MedicationOccurrencesCubit>().record(
      occurrence,
      DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt),
    );
  }

  Future<void> _skip(BuildContext context) async {
    final draft = await selectSkippedDose(context);
    if (draft == null || !context.mounted) return;
    await context.read<MedicationOccurrencesCubit>().record(occurrence, draft);
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
                        ? occurrence.takenLate
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
    final local = riyadhNow(takenAt);
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return formatMedicationTime(context, time);
  }
}

/// «ذكّرني لاحقًا»: the dose's own reminder again in 15 minutes, half an
/// hour or an hour, with the same words as its notification. The choices
/// open as a small Liquid Glass menu out of the button, like the circle
/// switcher, not a sheet from the bottom.
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
  /// While the menu is open the button hides: the menu grows out of it, so
  /// there is one piece of glass.
  bool _open = false;

  static const List<int> _choices = <int>[15, 30, 60];

  Widget _content(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const Icon(
        CupertinoIcons.bell,
        size: 16,
        color: AppSemanticColors.textPrimary,
      ),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Text(
          context.tr('reminders.snooze'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppSemanticColors.textPrimary),
        ),
      ),
    ],
  );

  Future<void> _snooze(BuildContext anchor) async {
    setState(() => _open = true);
    final int? minutes = await showGlassMenu<int>(
      anchorContext: anchor,
      semanticLabel: context.tr('reminders.snooze_title'),
      anchorContent: _content(context),
      sections: <List<GlassMenuItem<int>>>[
        <GlassMenuItem<int>>[
          for (final int value in _choices)
            GlassMenuItem<int>(
              value: value,
              label: afterDuration(context, value),
              icon: CupertinoIcons.clock,
            ),
        ],
      ],
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (minutes == null) return;
    // Only the reminder's words are needed, never who an appointment is for.
    final ReminderCircle circle = ReminderCircle(
      id: widget.circleId,
      name: '',
      viewerId: null,
      viewerIsPatient: false,
    );
    await GetIt.I<DoseReminders>().snooze(
      circleId: widget.circleId,
      task: SnoozedTask.dose,
      title: doseReminderTexts.title(circle, widget.occurrence),
      body: doseReminderTexts.body(circle, widget.occurrence),
      after: Duration(minutes: minutes),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'reminders.snoozed',
            args: <String>[afterDuration(context, minutes)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _open ? 0 : 1,
      child: Builder(
        builder: (BuildContext anchor) => FilledButton.tonalIcon(
          style: widget.style.copyWith(
            backgroundColor: const WidgetStatePropertyAll<Color>(
              AppSemanticColors.surfaceContent,
            ),
            foregroundColor: const WidgetStatePropertyAll<Color>(
              AppSemanticColors.textPrimary,
            ),
          ),
          onPressed: () => _snooze(anchor),
          icon: const Icon(CupertinoIcons.bell, size: 16),
          label: Text(context.tr('reminders.snooze')),
        ),
      ),
    );
  }
}
