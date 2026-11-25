import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/missed_measurement_card.dart';
import 'package:app/features/measurements/presentation/widgets/outside_reading_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The measurements that need attention. On «اليوم» they sit inside the one
/// «يحتاج انتباهك» box with the doses ([boxed] false: the cards only); on
/// its own ([boxed] true) it has its own yellow box and title. With the
/// [circleId], a missed task a tapped notification is about is brought
/// into view and tinted.
class MeasurementAttentionSection extends StatelessWidget {
  const MeasurementAttentionSection({
    super.key,
    required this.tasks,
    required this.readings,
    this.boxed = true,
    this.circleId,
  });

  final List<MeasurementOccurrence> tasks;
  final List<MeasurementReading> readings;
  final bool boxed;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final clock = PatientClockScope.of(context);
    final missed = MeasurementAttention.missed(tasks);
    final outside = MeasurementAttention.outside(readings, clock);
    if (missed.isEmpty && outside.isEmpty) return const SizedBox.shrink();
    final Widget cards = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: measurementAttentionCards(
        context,
        missed,
        outside,
        now: clock.now(),
        circleId: circleId,
      ),
    );
    if (!boxed) return cards;
    return AttentionBox(
      title: context.tr('measurements.needs_attention'),
      count: missed.length + outside.length,
      child: cards,
    );
  }
}

/// The cards of the attention box, drawn as readings are in «السجل»:
/// «سجّل» and «تخطي» for a missed task (only «تخطي» once the next task of
/// its kind is due at [now], a wall time), «تابعتها» for a reading outside
/// its normal range, with its value, level and range.
List<Widget> measurementAttentionCards(
  BuildContext context,
  List<MeasurementOccurrence> missed,
  List<MeasurementReading> outside, {
  required DateTime now,
  String? circleId,
}) => <Widget>[
  for (final MeasurementOccurrence task in missed)
    MissedMeasurementCard(task: task, now: now, circleId: circleId),
  for (final MeasurementReading reading in outside)
    OutsideReadingCard(reading: reading),
];

/// Which readings «السجل» shows: every kind, or one of them.
enum MeasurementRecordFilter {
  all,
  glucose,
  bp;

  /// The kind this filter keeps; null for [all].
  MeasurementKind? get kind => switch (this) {
    all => null,
    glucose => MeasurementKind.glucose,
    bp => MeasurementKind.bp,
  };

  /// Whether a reading of [value] belongs in the list.
  bool keeps(MeasurementKind value) => kind == null || kind == value;

  /// The key of its words: «الكل», «سكر الدم», «ضغط الدم».
  String get labelKey => switch (this) {
    all => 'measurements.all',
    glucose => 'measurements.glucose',
    bp => 'measurements.bp',
  };
}
