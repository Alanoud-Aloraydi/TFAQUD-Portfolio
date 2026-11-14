import 'package:app/features/appointments/domain/appointment.dart';
import 'package:equatable/equatable.dart';

enum AppointmentsLoadStatus { initial, loading, ready, failure }

/// The appointments of one circle, and what is being saved.
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
