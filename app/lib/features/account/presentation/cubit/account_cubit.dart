import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_loading.dart';
import 'package:app/features/account/presentation/cubit/account_profile_saving.dart';
import 'package:app/features/account/presentation/cubit/account_requests.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The account page (F05): the names, the phone number, the requests sent that
/// wait for the patient, changing the names, and deleting the account.
class AccountCubit extends Cubit<AccountState>
    with
        AccountScope,
        AccountLoading,
        AccountProfileSaving,
        AccountRequests,
        AccountDeleteRun,
        AccountDeleting {
  AccountCubit(this.circles, this.profile, this.auth, this.home)
    : super(const AccountState());

  @override
  final CirclesUseCase circles;
  @override
  final ProfileUseCase profile;
  @override
  final AuthUseCase auth;
  @override
  final HomeUseCase home;
}

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
