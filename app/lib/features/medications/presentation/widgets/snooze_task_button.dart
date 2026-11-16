import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button_label.dart';
import 'package:flutter/material.dart';

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
