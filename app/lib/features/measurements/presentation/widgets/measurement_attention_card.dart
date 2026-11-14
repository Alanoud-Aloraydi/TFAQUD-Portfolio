import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:flutter/cupertino.dart';

/// One card of the measurement attention box, drawn as a reading is in
/// «السجل» ([RecordItemCard]): the kind's icon (a drop for glucose, a heart
/// for blood pressure), [title] with when, [status] at the end (the value,
/// or why it waits), [lines] under them, then the buttons that answer it.
class MeasurementAttentionCard extends StatelessWidget {
  const MeasurementAttentionCard({
    super.key,
    required this.kind,
    required this.title,
    required this.status,
    required this.actions,
    this.lines = const <Widget>[],
  });

  final MeasurementKind kind;
  final Widget title;
  final Widget status;
  final List<Widget> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: RecordItemCard(
      leading: Icon(
        kind == MeasurementKind.glucose
            ? CupertinoIcons.drop
            : CupertinoIcons.heart,
      ),
      title: title,
      status: status,
      body: <Widget>[
        ...lines,
        Wrap(spacing: AppSpacing.sm, children: actions),
      ],
    ),
  );
}
