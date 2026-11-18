import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What every part of the appointments cubit works on: the repository, the
/// circle being shown and the two counters that keep readings and changes in
/// order.
mixin AppointmentsScope on Cubit<AppointmentsState> {
  AppointmentsUseCase get repository;

  /// The circle whose appointments are shown.
  String? openCircleId;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// True while a change is being sent: a second tap sends nothing.
  bool writing = false;
}
