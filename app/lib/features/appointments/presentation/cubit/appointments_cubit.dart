import 'dart:async';

import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_scope.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_writing.dart';
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
