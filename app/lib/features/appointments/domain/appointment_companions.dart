import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';

/// Who may go with the patient to a visit ([people], the circle's members),
/// and whether the patient has a phone: without one, a visit nobody goes
/// with reminds the circle's leader, and the form says so.
class AppointmentCompanions extends Equatable {
  const AppointmentCompanions(this.people, {this.patientHasPhone = true});

  final List<AppointmentCompanion> people;

  /// Whether the patient has an account in the app; true when an older
  /// server does not say.
  final bool patientHasPhone;

  @override
  List<Object?> get props => [people, patientHasPhone];
}
