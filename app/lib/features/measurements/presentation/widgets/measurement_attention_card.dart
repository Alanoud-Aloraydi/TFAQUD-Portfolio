import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
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

/// The measurements of «يحتاج انتباهك»: tasks nobody recorded, and today's
/// readings outside their target that nobody followed up yet.
abstract final class MeasurementAttention {
  /// The tasks nobody recorded.
  static List<MeasurementOccurrence> missed(
    List<MeasurementOccurrence> tasks,
  ) => tasks.where((item) => item.status == MeasurementStatus.missed).toList();

  /// The readings of the patient's today outside their target and not yet
  /// followed up.
  static List<MeasurementReading> outside(
    List<MeasurementReading> readings,
    PatientClock clock,
  ) => readings
      .where(
        (item) =>
            item.outsideTarget == true &&
            item.followedUpAt == null &&
            item.measuredAt != null &&
            clock.today(item.measuredAt!) == clock.today(),
      )
      .toList();

  /// How many cards the attention box shows for [clock]'s patient.
  static int count(
    List<MeasurementOccurrence> tasks,
    List<MeasurementReading> readings,
    PatientClock clock,
  ) => missed(tasks).length + outside(readings, clock).length;
}
