import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_delete_run.dart';
import 'package:app/features/account/presentation/cubit/account_deleting.dart';
import 'package:app/features/account/presentation/cubit/account_loading.dart';
import 'package:app/features/account/presentation/cubit/account_profile_saving.dart';
import 'package:app/features/account/presentation/cubit/account_requests.dart';
import 'package:app/features/account/presentation/cubit/account_scope.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
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
