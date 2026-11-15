import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:flutter/widgets.dart';

/// What a screen reader says for an appointment's row of «اليوم»: the
/// visit first, its clinic, then the clock and who goes.
String appointmentRowLabel(BuildContext context, CareAppointment value) =>
    <String>[
      appointmentTitle(context, value),
      if (appointmentClinic(value) case final String clinic) clinic,
      clockText(value.time),
      if (appointmentCompanionLine(context, value) case final String who
          when who.isNotEmpty)
        who,
    ].join('، ');
