import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the edit page of the medical file is bound to.
mixin MedicalFileEditScope on Cubit<MedicalFileEditState> {
  CirclesUseCase get circles;

  /// The circle whose file is edited.
  String get circleId;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;

  /// A refused save: the page stops saving and says why. Always false, so a
  /// save can return it.
  bool failed(Failure failure) {
    emit(
      state.copyWith(
        saving: false,
        errorKey: failure.messageKey,
        sessionEnded: endedSession(failure),
      ),
    );
    return false;
  }
}
