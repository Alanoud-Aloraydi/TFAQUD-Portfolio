import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_scope.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';

/// Reading and saving the written visit paper.
mixin VisitPaperActions on VisitScope {
  /// Reads the visit paper; [VisitState.loadFailed] says when it could not.
  Future<void> load() async {
    emit(state.copyWith(loading: true, loadFailed: false, clearError: true));
    try {
      final paper = await visits.get(circleId, appointmentId);
      if (!isClosed) {
        emit(state.copyWith(loading: false, paper: paper, replacePaper: true));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            loadFailed: true,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }

  /// Saves the written paper; false when the server said no.
  Future<bool> save(VisitPaperDraft draft) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final paper = await visits.save(circleId, appointmentId, draft);
      if (!isClosed) {
        emit(state.copyWith(saving: false, paper: paper, replacePaper: true));
      }
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            saving: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }
}
