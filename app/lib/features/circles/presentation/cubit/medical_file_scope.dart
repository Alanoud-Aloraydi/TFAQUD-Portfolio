import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the medical file page is bound to, shared by everything it does.
mixin MedicalFileScope on Cubit<MedicalFileState> {
  /// The use case the cubit was made with.
  CirclesUseCase get circles;

  /// The circle whose file is shown.
  String get circleId;

  /// Counts the readings, so a reading that started before a save is
  /// dropped when it arrives.
  int revision = 0;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
