import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_scope.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';

/// Reading a circle's appointments.
mixin AppointmentsLoading on AppointmentsScope {
  /// Reads [circleId]'s appointments; another circle's list is dropped first.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(String circleId, {bool silent = false}) async {
    if (isClosed) return;
    final changed = openCircleId != circleId;
    openCircleId = circleId;
    final current = ++revision;
    final bool keep =
        silent && !changed && state.status == AppointmentsLoadStatus.ready;
    if (!keep) {
      emit(
        AppointmentsState(
          status: AppointmentsLoadStatus.loading,
          appointments: changed ? const [] : state.appointments,
        ),
      );
    }
    try {
      final appointments = await repository.appointments(circleId);
      if (isClosed || current != revision) return;
      emit(
        AppointmentsState(
          status: AppointmentsLoadStatus.ready,
          appointments: appointments,
        ),
      );
    } catch (error) {
      if (isClosed || current != revision) return;
      emit(
        AppointmentsState(
          status: keep
              ? AppointmentsLoadStatus.ready
              : AppointmentsLoadStatus.failure,
          appointments: state.appointments,
          errorKey: keep
              ? null
              : FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }
}
