import 'package:app/features/appointments/domain/appointment_kind.dart';

/// The rows of the form's type choice; [AppointmentKind.other] stands alone.
enum AppointmentKindGroup {
  visit(<AppointmentKind>[
    AppointmentKind.followUp,
    AppointmentKind.newVisit,
    AppointmentKind.remote,
    AppointmentKind.emergency,
  ]),
  checks(<AppointmentKind>[
    AppointmentKind.test,
    AppointmentKind.imaging,
    AppointmentKind.eyeExam,
    AppointmentKind.hearingTest,
  ]),
  treatment(<AppointmentKind>[
    AppointmentKind.surgery,
    AppointmentKind.physio,
    AppointmentKind.dialysis,
    AppointmentKind.therapySession,
    AppointmentKind.dressing,
  ]),
  routine(<AppointmentKind>[
    AppointmentKind.vaccine,
    AppointmentKind.checkup,
    AppointmentKind.dental,
    AppointmentKind.pharmacy,
  ]),
  sessions(<AppointmentKind>[AppointmentKind.mental, AppointmentKind.speech]);

  const AppointmentKindGroup(this.kinds);

  final List<AppointmentKind> kinds;
}
