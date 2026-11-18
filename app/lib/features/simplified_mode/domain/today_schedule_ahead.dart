import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/today_task_statuses.dart';

/// Tomorrow's first dose not yet recorded, for «أول دواء غدًا ...»; null
/// when none.
DoseOccurrence? firstDoseOn(List<DoseOccurrence> doses, DateTime tomorrow) {
  final List<DoseOccurrence> tomorrowDoses = <DoseOccurrence>[
    for (final DoseOccurrence dose in doses)
      if (isSameDate(dose.scheduledOn, tomorrow) && dose.record == null) dose,
  ]..sort((a, b) => a.time.compareTo(b.time));
  return tomorrowDoses.firstOrNull;
}

/// The nearest scheduled appointment after the wall time [wall], on any
/// day; null when none.
CareAppointment? nextAppointment(
  List<CareAppointment> appointments,
  DateTime wall,
) {
  final List<CareAppointment> coming = <CareAppointment>[
    for (final CareAppointment item in appointments)
      if (item.status == AppointmentStatus.scheduled &&
          item.scheduledAt.isAfter(wall))
        item,
  ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return coming.firstOrNull;
}
