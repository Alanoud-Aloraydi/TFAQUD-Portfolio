import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Defines the supported appointments load status values.
enum AppointmentsLoadStatus { initial, loading, ready, failure }

/// Holds the appointments presentation state.
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

/// The appointments of one circle, and their changes.
///
/// The home tabs hold one; each appointment page holds its own. Each reads
/// again whenever the repository says the circle's appointments changed,
/// wherever the change was saved, so they never disagree.
class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit(this._repository) : super(const AppointmentsState()) {
    _changes = _repository.changes.listen((circleId) {
      if (circleId == _circleId) unawaited(load(circleId, silent: true));
    });
  }

  final AppointmentRepository _repository;
  late final StreamSubscription<String> _changes;
  String? _circleId;

  /// Goes up at each [load], so an older reading that ends later is dropped.
  int _revision = 0;

  /// True while a change is being sent: a second tap sends nothing.
  bool _writing = false;

  /// Reads [circleId]'s appointments; another circle's list is dropped first.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(String circleId, {bool silent = false}) async {
    if (isClosed) return;
    final changed = _circleId != circleId;
    _circleId = circleId;
    final revision = ++_revision;
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
      final appointments = await _repository.appointments(circleId);
      if (isClosed || revision != _revision) return;
      emit(
        AppointmentsState(
          status: AppointmentsLoadStatus.ready,
          appointments: appointments,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _revision) return;
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

  /// Adds an appointment to [circleId]; null when saved, else the message key.
  Future<String?> create(String circleId, AppointmentDraft draft) =>
      _write(circleId, () => _repository.create(circleId, draft));

  /// Changes [appointment]; null when saved, else the message key.
  Future<String?> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) => _write(circleId, () => _repository.revise(circleId, appointment, draft));

  /// Marks [appointment] attended or cancelled; null when saved, else the
  /// message key.
  Future<String?> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) => _write(
    circleId,
    () => _repository.setStatus(circleId, appointment, status),
  );

  /// A saved change reloads through the repository's changes. An appointment
  /// changed, closed or gone elsewhere reads the list again so the page shows
  /// the truth.
  Future<String?> _write(
    String circleId,
    Future<CareAppointment> Function() operation,
  ) async {
    if (_writing) return 'error.unknown';
    _writing = true;
    try {
      await operation();
      return null;
    } catch (error) {
      final Failure failure = FailureExceptions.getException(error);
      if (!isClosed &&
          _circleId == circleId &&
          (failure is ConflictFailure || failure is NotFoundFailure)) {
        unawaited(load(circleId));
      }
      return failure.messageKey;
    } finally {
      _writing = false;
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
