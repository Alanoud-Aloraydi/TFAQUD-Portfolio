import 'package:app/features/appointments/presentation/widgets/overdue_appointment_card.dart';
import 'package:app/features/home/presentation/today_snapshot.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The one «يحتاج انتباهك» box: the doses, then the measurements, then the
/// appointments of earlier days, all of the overdue days still open.
class TodayAttention extends StatelessWidget {
  const TodayAttention({
    super.key,
    required this.snapshot,
    required this.circleId,
    required this.canManage,
  });

  final TodaySnapshot snapshot;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final readings = context.watch<MeasurementReadingsCubit>().state.readings;
    return TodayMedicationAttentionSection(
      occurrences: snapshot.medications.attention,
      circleId: circleId,
      canManage: canManage,
      extraCount: snapshot.extraCount,
      extra: snapshot.extraCount == 0
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MeasurementAttentionSection(
                  tasks: snapshot.overdueMeasurements,
                  readings: readings,
                  boxed: false,
                ),
                for (final item in snapshot.overdueAppointments)
                  OverdueAppointmentCard(
                    value: item,
                    circleId: circleId,
                    canManage: canManage,
                  ),
              ],
            ),
    );
  }
}
