import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_cards.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The measurements that need attention. On «اليوم» they sit inside the one
/// «يحتاج انتباهك» box with the doses ([boxed] false: the cards only); on
/// its own ([boxed] true) it has its own yellow box and title.
class MeasurementAttentionSection extends StatelessWidget {
  const MeasurementAttentionSection({
    super.key,
    required this.tasks,
    required this.readings,
    this.boxed = true,
  });

  final List<MeasurementOccurrence> tasks;
  final List<MeasurementReading> readings;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final missed = MeasurementAttention.missed(tasks);
    final outside = MeasurementAttention.outside(
      readings,
      PatientClockScope.of(context),
    );
    if (missed.isEmpty && outside.isEmpty) return const SizedBox.shrink();
    final Widget cards = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: measurementAttentionCards(context, missed, outside),
    );
    if (!boxed) return cards;
    return AttentionBox(
      title: context.tr('measurements.needs_attention'),
      count: missed.length + outside.length,
      child: cards,
    );
  }
}
