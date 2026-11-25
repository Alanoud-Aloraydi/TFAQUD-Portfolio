import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/features/home/presentation/widgets/next_task_card.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The next-task card, or the note that nothing is planned (or left) today.
/// The notes show only once [settled]: everything is read, with no failure.
class TodayNextOrEmpty extends StatelessWidget {
  const TodayNextOrEmpty({
    super.key,
    required this.snapshot,
    required this.next,
    required this.settled,
    required this.circleId,
    required this.canManage,
    this.onAdd,
  });

  final TodaySnapshot snapshot;
  final NextTask? next;
  final bool settled;
  final String circleId;
  final bool canManage;

  /// Opens the add sheet; null for a member who only reads, and the notes
  /// then have no button.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final NextTask? next = this.next;
    final bool nothingLeft =
        settled &&
        snapshot.medications.todayOccurrences.isNotEmpty &&
        snapshot.medications.attention.isEmpty &&
        snapshot.todayMeasurements.isEmpty &&
        snapshot.todayAppointments.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (settled && snapshot.dayIsEmpty)
          TodayEmptyNote(
            CareVoice.tr(context, circleId, 'today_dashboard.no_tasks_today'),
            onAdd: onAdd,
          ),
        if (next != null)
          NextTaskCard(
            task: next,
            circleId: circleId,
            canManage: canManage,
            now: snapshot.now,
          ),
        if (next != null) const SizedBox(height: AppSpacing.md),
        if (next == null && nothingLeft)
          TodayEmptyNote(
            context.tr('today_dashboard.no_remaining_tasks'),
            onAdd: onAdd,
          ),
      ],
    );
  }
}

/// A note on «اليوم» that nothing is planned (or left), with the button
/// that opens the add sheet when [onAdd] is not null.
class TodayEmptyNote extends StatelessWidget {
  const TodayEmptyNote(this.text, {super.key, required this.onAdd});

  final String text;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: EmptyStateNote(
      text,
      actionLabel: onAdd == null ? null : context.tr('add.title'),
      onAction: onAdd,
    ),
  );
}
