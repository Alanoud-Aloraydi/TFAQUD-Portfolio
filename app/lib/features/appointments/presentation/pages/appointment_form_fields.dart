import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_reminder_lead.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the appointment form holds while it is filled in: the kind, clinic,
/// days, time, place, reminder and companions, and whether it is saving.
mixin AppointmentFormFields on State<AppointmentFormPage> {
  AppointmentKind kind = AppointmentKind.followUp;

  /// The visit days, oldest first, all in «أيام المواعيد»: a new visit
  /// starts on the patient's today; an edited one is its own day alone.
  late List<DateTime> days = <DateTime>[PatientClockScope.of(context).today()];
  TimeOfDay time = const TimeOfDay(hour: 10, minute: 0);
  String remoteMethod = 'video';
  final Set<String> companionIds = <String>{};

  /// How long before the visit its near reminder comes.
  int lead = defaultAppointmentLead;
  final place = TextEditingController();
  final clinic = TextEditingController();
  final otherKind = TextEditingController();
  bool _initialized = false;
  bool saving = false;
  String? errorKey;

  /// The error under the field it is about ([key]), while it is the one.
  String? fieldError(String key) => errorKey == key ? context.tr(key) : null;

  /// Lets the parts of the form change it and draw it again.
  void update(VoidCallback change) => setState(change);

  @override
  void dispose() {
    place.dispose();
    clinic.dispose();
    otherKind.dispose();
    super.dispose();
  }

  void fill(CareAppointment value) {
    if (_initialized) return;
    _initialized = true;
    clinic.text = value.specialty ?? '';
    kind = value.kind;
    otherKind.text = value.otherKind ?? '';
    days = <DateTime>[value.scheduledOn];
    final parts = value.time.split(':');
    time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    place.text = value.place ?? '';
    remoteMethod = value.remoteMethod ?? 'video';
    lead = value.reminderLeadMinutes;
    companionIds
      ..clear()
      ..addAll(value.companions.map((item) => item.id));
  }
}

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
