import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// «ذكّرني لاحقًا» as a task button: a bell that fills once the dose is put
/// off, and says by whom and until when.
class SnoozeTaskButton extends StatelessWidget {
  const SnoozeTaskButton({
    super.key,
    required this.at,
    required this.shared,
    required this.onPressed,
  });

  /// When this phone's own reminder will come back, if it was put off here.
  final DateTime? at;

  /// The circle's own snooze, when someone else put the dose off.
  final SharedSnooze? shared;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TaskButton(
    role: TaskButtonRole.later,
    icon: snoozeButtonIcon(at, shared),
    label: snoozeButtonLabel(context, at, shared),
    onPressed: onPressed,
  );
}

/// «ذكّرني لاحقًا»; «بنذكّرك 2:36 م» while this phone put the dose off
/// ([at]); «مؤجّلة إلى 2:36 م، لين» while someone else did ([shared]).
String snoozeButtonLabel(
  BuildContext context,
  DateTime? at,
  SharedSnooze? shared,
) {
  String clock(DateTime moment) =>
      wallTimeText(PatientClockScope.of(context).wallTime(moment));
  if (at != null) {
    return context.tr('reminders.snoozed', args: <String>[clock(at)]);
  }
  if (shared == null) return context.tr('reminders.snooze');
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

/// A full bell once the dose is put off, by whoever did it.
IconData snoozeButtonIcon(DateTime? at, SharedSnooze? shared) =>
    at == null && shared == null
    ? CupertinoIcons.bell
    : CupertinoIcons.bell_fill;
