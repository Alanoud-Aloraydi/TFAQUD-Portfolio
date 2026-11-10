import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the appointment companions presentation state.
class AppointmentCompanionsState extends Equatable {
  const AppointmentCompanionsState({
    this.loading = true,
    this.companions = const [],
    this.errorKey,
  });

  final bool loading;
  final List<AppointmentCompanion> companions;
  final String? errorKey;

  @override
  List<Object?> get props => [loading, companions, errorKey];
}

/// Coordinates appointment companions actions and UI state.
class AppointmentCompanionsCubit extends Cubit<AppointmentCompanionsState> {
  AppointmentCompanionsCubit(this._repository)
    : super(const AppointmentCompanionsState());

  final AppointmentRepository _repository;

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
