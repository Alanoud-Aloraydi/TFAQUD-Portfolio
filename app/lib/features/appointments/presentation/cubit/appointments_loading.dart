import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

enum AppointmentsLoadStatus { initial, loading, ready, failure }

/// The appointments of one circle, and what is being saved.
class AppointmentsState extends Equatable {
  const AppointmentsState({
    this.status = AppointmentsLoadStatus.initial,
    this.appointments = const [],
    this.errorKey,
  });

  final AppointmentsLoadStatus status;
  final List<CareAppointment> appointments;
  final String? errorKey;

  @override
  List<Object?> get props => [status, appointments, errorKey];
}

/// What every part of the appointments cubit works on: the repository, the
/// circle being shown and the two counters that keep readings and changes in
/// order.
mixin AppointmentsScope on Cubit<AppointmentsState> {
  AppointmentsUseCase get repository;

  /// The circle whose appointments are shown.
  String? openCircleId;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// True while a change is being sent: a second tap sends nothing.
  bool writing = false;
}
