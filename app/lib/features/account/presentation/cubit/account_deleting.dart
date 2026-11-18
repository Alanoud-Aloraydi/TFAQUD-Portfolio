import 'package:app/features/account/presentation/cubit/account_delete_run.dart';
import 'package:app/features/account/presentation/cubit/account_scope.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';

/// Deleting the account, one question at a time.
mixin AccountDeleting on AccountScope, AccountDeleteRun {
  /// Asks the first question: "Delete your account?".
  void startDelete() {
    if (state.deleting) return;
    emit(
      state.copyWith(
        deletePrompt: DeletePrompt.confirm,
        deletion: const AccountDeletion(),
        clearMessages: true,
      ),
    );
  }

  /// The person answered no to a question: nothing is deleted.
  void cancelDelete() {
    emit(
      state.copyWith(
        deletePrompt: DeletePrompt.none,
        deletion: const AccountDeletion(),
      ),
    );
  }

  /// The person answered yes to the first question.
  Future<void> confirmDelete() => runDelete(const AccountDeletion());

  /// The person chose what happens to the circle they receive care in.
  Future<void> choosePatient(PatientChoice choice) =>
      runDelete(state.deletion.copyWith(patientChoice: choice));

  /// The person agreed to delete the circles they are the only manager of.
  Future<void> confirmLastManager() =>
      runDelete(state.deletion.copyWith(deleteLastManagedCircles: true));
}
