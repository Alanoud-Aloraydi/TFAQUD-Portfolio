import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorded_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_recording_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_regular_controls.dart';
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
      return DoseRecordedStatus(occurrence: occurrence, circleId: circleId);
    }
    final isRecording = context.select<MedicationOccurrencesCubit, bool>(
      (cubit) => cubit.state.recordingOccurrence == occurrence,
    );
    if (isRecording) return const DoseRecordingStatus();
    final today = PatientClockScope.of(context).today();
    final scheduledOn = scheduleDay(occurrence.scheduledOn);
    if (scheduledOn.isAfter(today)) return const SizedBox.shrink();
    final isToday = scheduledOn == today;
    if (layout != DoseControlsLayout.regular) {
      // One button system for every task (TaskButtonRole): each answer its
      // own color and icon, all 48 high, two to a line of equal widths.
      String say(String key) => CareVoice.tr(context, circleId, key);
      return TaskButtonGrid(
        buttons: <Widget>[
          if (isToday)
            // A day of four doses shows four «انأخذت»: read aloud they are
            // the same word, so the reader is told which medicine.
            TaskButton(
              role: TaskButtonRole.answer,
              icon: CupertinoIcons.checkmark,
              label: say('medications.taken_short'),
              semanticLabel:
                  '${say('medications.taken_short')}، ${occurrence.name}',
              onPressed: () =>
                  takeDoseNow(context, occurrence, circleId: circleId),
            ),
          if (isToday && circleId != null)
            _SnoozeButton(occurrence: occurrence, circleId: circleId!),
          TaskButton(
            role: TaskButtonRole.earlier,
            icon: CupertinoIcons.clock,
            label: say('medications.different_time_short'),
            onPressed: () => takeDoseAtDifferentTime(
              context,
              occurrence,
              circleId: circleId,
            ),
          ),
          TaskButton(
            role: TaskButtonRole.skip,
            icon: CupertinoIcons.minus_circle,
            label: context.tr('medications.skip_short'),
            onPressed: () => skipDose(context, occurrence, circleId: circleId),
          ),
        ],
      );
    }
    return doseRegularControls(
      context,
      occurrence: occurrence,
      isToday: isToday,
      circleId: circleId,
    );
  }
}

/// «ذكّرني لاحقًا»: the dose's own reminder again, as late as the person
/// slides the ruler of [showSnoozeSheet] (5 minutes a mark, up to 12 hours,
/// and never past halfway to the medicine's next dose), with the same
/// words as its notification. Once put off, the button says when it comes
/// («بنذكّرك 2:36 م»), and opens the ruler again. Put off by someone else
/// in the circle, it says until when and who («مؤجّلة إلى 2:36 م، لين»).
class _SnoozeButton extends StatefulWidget {
  const _SnoozeButton({required this.occurrence, required this.circleId});

  final DoseOccurrence occurrence;
  final String circleId;

  @override
  State<_SnoozeButton> createState() => _SnoozeButtonState();
}

class _SnoozeButtonState extends State<_SnoozeButton> {
  /// The reminders, where the app has them (a test of a card may not).
  DoseReminders? get _reminders =>
      GetIt.I.isRegistered<DoseReminders>() ? GetIt.I<DoseReminders>() : null;

  /// «ذكّرني لاحقًا»; «بنذكّرك 2:36 م» while this phone put the dose off
  /// ([at]); «مؤجّلة إلى 2:36 م، لين» while someone else did ([shared]).
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
      TaskButton(
        role: TaskButtonRole.later,
        icon: _icon(at, shared),
        label: _label(context, at, shared),
        onPressed: _snooze,
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
