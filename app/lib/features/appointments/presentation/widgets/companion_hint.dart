import 'package:app/features/appointments/presentation/cubit/appointment_companions_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The note under «المرافقون»: who the visit reminds. The patient and the
/// companions [chosen]; for a patient without a phone, the companions, or
/// the circle's leader when nobody goes with them.
String companionHint(
  BuildContext context,
  AppointmentCompanionsState state,
  Set<String> chosen,
) => context.tr(
  state.patientHasPhone
      ? 'appointments.companion_hint'
      : chosen.isEmpty
      ? 'appointments.companion_hint_leader'
      : 'appointments.companion_hint_no_phone',
);
