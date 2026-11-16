import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';

/// The circle's members who can go with the patient.
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
