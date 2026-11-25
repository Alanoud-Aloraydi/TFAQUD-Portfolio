import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:get_it/get_it.dart';

/// The account's cubit, reading the account; the account pages of both
/// modes share it.
AccountCubit loadedAccountCubit() => AccountCubit(
  GetIt.I<CirclesUseCase>(),
  GetIt.I<ProfileUseCase>(),
  GetIt.I<AuthUseCase>(),
  GetIt.I<HomeUseCase>(),
)..load();
