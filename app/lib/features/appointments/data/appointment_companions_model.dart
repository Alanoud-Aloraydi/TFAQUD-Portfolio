import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_companions.dart';

/// Reads the answer of `GET …/appointments/companions`: the members who
/// may go, and whether the patient has an account (true from an older
/// server, which does not say).
AppointmentCompanions companionsFromJson(Map<String, dynamic> body) =>
    AppointmentCompanions(<AppointmentCompanion>[
      for (final Object? item in body['companions'] as List<dynamic>)
        AppointmentModel.companionFromJson(item! as Map<String, dynamic>),
    ], patientHasPhone: body['patient_has_account'] as bool? ?? true);
