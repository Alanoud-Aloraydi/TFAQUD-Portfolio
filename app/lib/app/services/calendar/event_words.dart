part of 'package:app/app/services/calendar_sync.dart';

/// The Arabic words, read when the events are set (the translations are
/// loaded by then).
final CalendarEventTexts calendarEventTexts = CalendarEventTexts(
  dose: (String circleId, String medicine) {
    final String? patient = CareVoice.patientOf(circleId);
    return patient == null
        ? 'reminders.dose_call'.tr(args: <String>[withArticle(medicine)])
        : 'reminders.dose_call_for'.tr(
            args: <String>[withArticle(medicine), patient],
          );
  },
  doseNote: () => 'reminders.dose_title'.tr(),
  measurement: (String circleId, MeasurementKind kind) {
    final String name = switch (kind) {
      MeasurementKind.glucose => 'measurements.glucose'.tr(),
      MeasurementKind.bp => 'measurements.bp'.tr(),
    };
    final String? patient = CareVoice.patientOf(circleId);
    return 'reminders.calendar_measurement'.tr(
      args: <String>[
        if (patient == null)
          name
        else
          'reminders.measurement_body_for'.tr(args: <String>[name, patient]),
      ],
    );
  },
  appointment: (String circleId, CareAppointment visit) {
    final String? patient = CareVoice.patientOf(circleId);
    final String clinic = visitName(visit);
    return patient == null
        ? 'reminders.calendar_appointment'.tr(args: <String>[clinic])
        : 'reminders.calendar_appointment_for'.tr(
            args: <String>[patient, clinic],
          );
  },
  appointmentNote: (CareAppointment visit) {
    final String place = visit.place?.trim() ?? '';
    final List<String> args = <String>[
      visitName(visit),
      clockText(visit.time),
      if (place.isNotEmpty) place,
    ];
    return (place.isEmpty
            ? 'reminders.appointment_body'
            : 'reminders.appointment_body_place')
        .tr(args: args);
  },
);
