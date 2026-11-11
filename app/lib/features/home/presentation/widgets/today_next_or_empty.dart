import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/features/home/presentation/today_snapshot.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
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
  });

  final TodaySnapshot snapshot;
  final NextTask? next;
  final bool settled;
  final String circleId;
  final bool canManage;

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
          _note(
            context,
            CareVoice.tr(context, circleId, 'today_dashboard.no_tasks_today'),
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
          _note(context, context.tr('today_dashboard.no_remaining_tasks')),
      ],
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: EmptyStateNote(
      text,
      actionLabel: context.tr('add.title'),
      onAction: () => showHomeAddSheet(context, circleId: circleId),
    ),
  );
}
