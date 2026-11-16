import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_state.dart';
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
          AppointmentCompanionsState(loading: false, companions: companions),
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
