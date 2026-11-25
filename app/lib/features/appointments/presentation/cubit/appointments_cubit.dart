import 'dart:async';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The appointments of one circle, and their changes.
///
/// The home tabs hold one; each appointment page holds its own. Each reads
/// again whenever the repository says the circle's appointments changed,
/// wherever the change was saved, so they never disagree.
class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit(this.repository) : super(const AppointmentsState()) {
    _changes = repository.changes.listen((circleId) {
      if (circleId == openCircleId) unawaited(load(circleId, silent: true));
    });
  }

  final AppointmentsUseCase repository;
  late final StreamSubscription<String> _changes;

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }

  /// The circle whose appointments are shown.
  String? openCircleId;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// True while a change is being sent: a second tap sends nothing.
  bool writing = false;

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

  /// Adds an appointment to [circleId]; null when saved, else the message key.
  Future<String?> create(String circleId, AppointmentDraft draft) =>
      _write(circleId, () => repository.create(circleId, draft));

  /// Changes [appointment]; null when saved, else the message key.
  Future<String?> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) => _write(circleId, () => repository.revise(circleId, appointment, draft));

  /// Marks [appointment] attended or cancelled; null when saved, else the
  /// message key.
  Future<String?> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) => _write(
    circleId,
    () => repository.setStatus(circleId, appointment, status),
  );

  /// Changes how [appointment] went (السجل); null when saved, else a key.
  Future<String?> changeOutcome(
    String circleId,
    CareAppointment appointment,
    AppointmentOutcome outcome,
  ) => _write(
    circleId,
    () => repository.changeOutcome(circleId, appointment, outcome),
  );

  /// A saved change reloads through the repository's changes. An appointment
  /// changed, closed or gone elsewhere reads the list again so the page shows
  /// the truth.
  Future<String?> _write(
    String circleId,
    Future<CareAppointment> Function() operation,
  ) async {
    if (writing) return 'error.unknown';
    writing = true;
    try {
      await operation();
      return null;
    } catch (error) {
      final Failure failure = FailureExceptions.getException(error);
      if (!isClosed &&
          openCircleId == circleId &&
          (failure is ConflictFailure || failure is NotFoundFailure)) {
        unawaited(load(circleId));
      }
      return failure.messageKey;
    } finally {
      writing = false;
    }
  }
}
