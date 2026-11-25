import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/features/appointments/presentation/widgets/overdue_appointment_card.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_attention_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The one «يحتاج انتباهك» box: the doses, then the measurements, then the
/// appointments of earlier days, all of the overdue days still open. The
/// card a tapped notification is about is brought into view and tinted.
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
      focusKeys: attentionFocusKeys(snapshot, circleId),
      extra: snapshot.extraCount == 0
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MeasurementAttentionSection(
                  tasks: snapshot.overdueMeasurements,
                  readings: readings,
                  boxed: false,
                  circleId: circleId,
                ),
                for (final item in snapshot.overdueAppointments)
                  FocusMark(
                    itemKey: appointmentItemKey(circleId, item.id),
                    radius: AppRadius.field,
                    inset: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: OverdueAppointmentCard(
                      value: item,
                      circleId: circleId,
                      canManage: canManage,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Every item of the «يحتاج انتباهك» box of [snapshot], as a tapped
/// notification names it (item_keys.dart): its doses, its measurements and
/// its visits.
Set<String> attentionFocusKeys(TodaySnapshot snapshot, String circleId) =>
    <String>{
      for (final dose in snapshot.medications.attention)
        doseSnoozeKey(circleId, dose),
      for (final task in snapshot.overdueMeasurements)
        measurementSnoozeKey(circleId, task),
      for (final item in snapshot.overdueAppointments)
        appointmentItemKey(circleId, item.id),
    };
