import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/loaded_account_cubit.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The account page and its edit page.
List<RouteBase> accountRoutes() => <RouteBase>[
  // The account page: names, phone number, requests that wait for the
  // patient, sign-out (AuthCubit) and deleting the account.
  GoRoute(
    path: Routes.account,
    pageBuilder: iosModalPage(
      (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => loadedAccountCubit()),
          BlocProvider(create: (context) => AuthCubit(GetIt.I<AuthUseCase>())),
        ],
        child: const AccountScreen(),
      ),
    ),
  ),
  GoRoute(
    path: Routes.accountEdit,
    pageBuilder: iosPage(
      (context, state) => BlocProvider(
        create: (context) => loadedAccountCubit(),
        child: const AccountEditScreen(),
      ),
    ),
  ),
];
