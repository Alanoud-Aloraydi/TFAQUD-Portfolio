import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// One appointment's line in the exported record: the day, the time, what
/// it is, where, who goes with the patient, and what became of it.
List<RecordPdfCell> appointmentRow(BuildContext context, CareAppointment item) {
  final String place = item.kind == AppointmentKind.remote
      ? context.tr('appointments.${item.remoteMethod}')
      : item.place ?? '';
  final String? clinic = appointmentClinic(item);
  return <RecordPdfCell>[
    RecordPdfCell(appointmentDate(context, item.scheduledOn)),
    RecordPdfCell(clockText(item.time), ltr: true),
    RecordPdfCell(
      clinic == null
          ? appointmentTitle(context, item)
          : '${appointmentTitle(context, item)}، $clinic',
    ),
    RecordPdfCell(place),
    RecordPdfCell(appointmentCompanionNames(context, item)),
    RecordPdfCell(
      context.tr('appointments.status.${item.status.name}'),
      // An appointment nobody attended is the line a reader looks for.
      warn: item.status != AppointmentStatus.completed,
    ),
  ];
}
