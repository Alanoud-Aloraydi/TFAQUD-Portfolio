import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates appointment companions actions and UI state.
class AppointmentCompanionsCubit extends Cubit<AppointmentCompanionsState> {
  AppointmentCompanionsCubit(this._repository)
    : super(const AppointmentCompanionsState());

  final AppointmentsUseCase _repository;

  Future<void> load(String circleId) async {
    emit(const AppointmentCompanionsState());
    try {
      final companions = await _repository.companions(circleId);
      if (!isClosed) {
        emit(
          AppointmentCompanionsState(
            loading: false,
            companions: companions.people,
            patientHasPhone: companions.patientHasPhone,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          AppointmentCompanionsState(
            loading: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }
}

/// The circle's members who can go with the patient, and whether the
/// patient has a phone (who a visit nobody goes with reminds).
class AppointmentCompanionsState extends Equatable {
  const AppointmentCompanionsState({
    this.loading = true,
    this.companions = const [],
    this.patientHasPhone = true,
    this.errorKey,
  });

  final bool loading;
  final List<AppointmentCompanion> companions;
  final bool patientHasPhone;
  final String? errorKey;

  @override
  List<Object?> get props => [loading, companions, patientHasPhone, errorKey];
}
