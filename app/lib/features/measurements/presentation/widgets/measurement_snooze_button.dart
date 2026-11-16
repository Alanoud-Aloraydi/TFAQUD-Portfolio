import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_snooze_button_state.dart';
import 'package:flutter/material.dart';

/// «ذكّرني لاحقًا» for a measurement: the same ruler, the same words and
/// the same look a dose has, so every task on «اليوم» answers the same
/// way — the reading had only «تسجيل قراءة» and «تخطي» before, and a
/// person who could not measure right now had nowhere to put it.
class MeasurementSnoozeButton extends StatefulWidget {
  const MeasurementSnoozeButton({
    super.key,
    required this.task,
    required this.circleId,
  });

  final MeasurementOccurrence task;
  final String circleId;

  @override
  State<MeasurementSnoozeButton> createState() =>
      MeasurementSnoozeButtonState();
}
