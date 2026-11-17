import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';

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
