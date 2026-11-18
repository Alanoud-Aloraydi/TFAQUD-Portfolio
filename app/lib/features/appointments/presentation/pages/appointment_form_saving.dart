import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_draft.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Saving the appointment form.
mixin AppointmentFormSaving on AppointmentFormDraft {
  /// Checks the form, then adds the appointment (or changes [value]) and
  /// leaves with `true`; a refusal shows under its field, or as a message.
  Future<void> save(CareAppointment? value) async {
    if (saving) return;
    final missingKey = missing;
    if (missingKey != null) {
      setState(() => errorKey = missingKey);
      return;
    }
    final draft = this.draft;
    if (wallClockAt(
      draft.scheduledOn,
      draft.time,
    ).isBefore(PatientClockScope.of(context).now())) {
      setState(() => errorKey = 'appointments.time_in_past');
      return;
    }
    setState(() {
      saving = true;
      errorKey = null;
    });
    final cubit = context.read<AppointmentsCubit>();
    final refused = value == null
        ? await cubit.create(widget.circleId, draft)
        : await cubit.revise(widget.circleId, value, draft);
    if (!mounted) return;
    if (refused == null) {
      AppToast.show(context, 'toast.appointment_saved');
      context.pop(true);
      return;
    }
    setState(() => saving = false);
    // The visit's time is checked again by the server; anything else is
    // about no one field: a short message.
    if (refused == 'appointments.time_in_past') {
      setState(() => errorKey = refused);
    } else {
      AppToast.show(context, refused, kind: ToastKind.error);
    }
  }
}
