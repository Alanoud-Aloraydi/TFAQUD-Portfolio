import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';

/// The form read as a visit: what it still lacks, and the draft it makes.
mixin AppointmentFormDraft on AppointmentFormFields {
  /// The message key of the first thing the form still needs, or null.
  String? get missing {
    if (kind == AppointmentKind.other && otherKind.text.trim().isEmpty) {
      return 'appointments.kind_required';
    }
    if (kind != AppointmentKind.remote && place.text.trim().isEmpty) {
      return 'appointments.place_required';
    }
    if (days.isEmpty) return 'appointments.days_required';
    return null;
  }

  /// Read only once [missing] is null: the first day must be there.
  AppointmentDraft get draft => AppointmentDraft(
    specialty: clinic.text.trim().isEmpty ? null : clinic.text.trim(),
    kind: kind,
    otherKind: kind == AppointmentKind.other ? otherKind.text.trim() : null,
    scheduledOn: days.first,
    time:
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}',
    place: kind == AppointmentKind.remote ? null : place.text.trim(),
    remoteMethod: kind == AppointmentKind.remote ? remoteMethod : null,
    companionAccountIds: companionIds.toList(),
    reminderLeadMinutes: lead,
    alsoOn: days.skip(1).toList(),
  );
}
