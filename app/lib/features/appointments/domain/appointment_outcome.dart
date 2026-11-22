import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';

/// How a visit went, as «السجل» lets it be changed: «حضرت», «ملغى» and
/// «فائت» once its time came, and «قادم» again for a cancelled visit still
/// ahead. Its [name] is what the server keeps (backend
/// appointment_outcomes.py); [labelKey] is its words, the badge's own.
enum AppointmentOutcome {
  scheduled,
  completed,
  cancelled,
  missed;

  String get labelKey => 'appointments.status.$name';
}

extension AppointmentOutcomes on CareAppointment {
  /// What can be chosen for the visit at [now] (the patient's wall time),
  /// in the order the menu lists them; empty when its badge cannot be
  /// pressed (a visit still ahead and not cancelled).
  List<AppointmentOutcome> outcomesAt(DateTime now) => !scheduledAt.isAfter(now)
      ? const <AppointmentOutcome>[
          AppointmentOutcome.completed,
          AppointmentOutcome.cancelled,
          AppointmentOutcome.missed,
        ]
      : status == AppointmentStatus.cancelled
      ? const <AppointmentOutcome>[
          AppointmentOutcome.scheduled,
          AppointmentOutcome.cancelled,
        ]
      : const <AppointmentOutcome>[];

  /// The outcome its badge says now, ticked in the menu; null for a visit
  /// whose time passed with no answer yet («لم يُؤكَّد الحضور»).
  AppointmentOutcome? outcomeOn(DateTime now, DateTime today) =>
      switch (status) {
        AppointmentStatus.completed => AppointmentOutcome.completed,
        AppointmentStatus.cancelled => AppointmentOutcome.cancelled,
        AppointmentStatus.scheduled when isMissedOn(today) =>
          AppointmentOutcome.missed,
        AppointmentStatus.scheduled when scheduledAt.isAfter(now) =>
          AppointmentOutcome.scheduled,
        AppointmentStatus.scheduled => null,
      };

  /// Whether «حضرت» stays because its «ورقة الزيارة» has something in it.
  bool get outcomeLocked =>
      status == AppointmentStatus.completed && visitFilled;
}
