import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_draft.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_saving.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_form_bar.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_form_body.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_form_missing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Adds or edits a visit: its kind, clinic, date, time, place and companions.
class AppointmentFormPage extends StatefulWidget {
  const AppointmentFormPage({
    super.key,
    required this.circleId,
    this.appointmentId,
  });

  final String circleId;
  final String? appointmentId;

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage>
    with AppointmentFormFields, AppointmentFormDraft, AppointmentFormSaving {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppointmentsCubit>().state;
    final companions = context.watch<AppointmentCompanionsCubit>().state;
    CareAppointment? appointment;
    if (widget.appointmentId != null) {
      for (final item in state.appointments) {
        if (item.id == widget.appointmentId) appointment = item;
      }
      if (appointment != null) fill(appointment);
      if (appointment == null) {
        return AppointmentFormMissing(state: state, circleId: widget.circleId);
      }
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        title: AppointmentFormBar(
          editing: appointment != null,
          onSave: saving ? null : () => save(appointment),
        ),
      ),
      body: AppointmentFormBody(form: this, companions: companions),
    );
  }
}
