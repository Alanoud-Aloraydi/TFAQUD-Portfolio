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
class AppointmentsCubit extends Cubit<AppointmentsState>
    with AppointmentsScope, AppointmentsLoading, AppointmentsWriting {
  AppointmentsCubit(this.repository) : super(const AppointmentsState()) {
    _changes = repository.changes.listen((circleId) {
      if (circleId == openCircleId) unawaited(load(circleId, silent: true));
    });
  }

  @override
  final AppointmentsUseCase repository;
  late final StreamSubscription<String> _changes;

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

/// Adding, changing and marking appointments.
mixin AppointmentsWriting on AppointmentsScope, AppointmentsLoading {
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
