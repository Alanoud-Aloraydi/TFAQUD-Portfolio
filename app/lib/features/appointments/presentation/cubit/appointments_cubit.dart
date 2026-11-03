import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppointmentsLoadStatus { initial, loading, ready, failure }

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

class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit(this._repository) : super(const AppointmentsState());

  final AppointmentRepository _repository;
  String? _circleId;
  int _revision = 0;

  Future<void> load(String circleId) async {
    final changed = _circleId != circleId;
    _circleId = circleId;
    final revision = ++_revision;
    emit(
      AppointmentsState(
        status: AppointmentsLoadStatus.loading,
        appointments: changed ? const [] : state.appointments,
      ),
    );
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
          status: AppointmentsLoadStatus.failure,
          appointments: state.appointments,
          errorKey: FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  Future<bool> create(AppointmentDraft draft) =>
      _write((circleId) => _repository.create(circleId, draft));

  Future<bool> revise(CareAppointment appointment, AppointmentDraft draft) =>
      _write((circleId) => _repository.revise(circleId, appointment, draft));

  Future<bool> setStatus(
    CareAppointment appointment,
    AppointmentStatus status,
  ) => _write(
    (circleId) => _repository.setStatus(circleId, appointment, status),
  );

  Future<bool> _write(
    Future<CareAppointment> Function(String circleId) operation,
  ) async {
    final circleId = _circleId;
    if (circleId == null) return false;
    try {
      await operation(circleId);
      if (!isClosed) await load(circleId);
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          AppointmentsState(
            status: AppointmentsLoadStatus.ready,
            appointments: state.appointments,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }
}
