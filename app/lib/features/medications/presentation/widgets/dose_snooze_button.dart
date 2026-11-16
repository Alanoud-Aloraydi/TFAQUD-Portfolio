import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_snooze_face.dart';
import 'package:app/features/medications/presentation/widgets/dose_snooze_request.dart';
import 'package:app/features/medications/presentation/widgets/dose_snooze_waiting.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// «ذكّرني لاحقًا»: the dose's own reminder again, as late as the person
/// slides the ruler of [requestDoseSnooze] (5 minutes a mark, up to 12
/// hours, and never past halfway to the medicine's next dose), with the
/// same words as its notification. Once put off, the button says when it
/// comes («بنذكّرك 2:36 م»), and opens the ruler again. Put off by someone
/// else in the circle, it says until when and who («مؤجّلة إلى 2:36 م،
/// لين»).
class DoseSnoozeButton extends StatefulWidget {
  const DoseSnoozeButton({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.style,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final ButtonStyle style;

  @override
  State<DoseSnoozeButton> createState() => _DoseSnoozeButtonState();
}

class _DoseSnoozeButtonState extends State<DoseSnoozeButton> {
  /// The reminders, where the app has them (a test of a card may not).
  DoseReminders? get _reminders =>
      GetIt.I.isRegistered<DoseReminders>() ? GetIt.I<DoseReminders>() : null;

  Future<void> _snooze() => requestDoseSnooze(
    context,
    occurrence: widget.occurrence,
    circleId: widget.circleId,
    reminders: _reminders,
  );

  Widget _button(BuildContext context, DateTime? at, SharedSnooze? shared) =>
      doseSnoozeFace(
        context,
        style: widget.style,
        at: at,
        shared: shared,
        onPressed: _snooze,
      );

  @override
  Widget build(BuildContext context) {
    final SharedSnooze? waiting = doseSnoozeWaiting(context, widget.occurrence);
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
