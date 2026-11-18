import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/pages/auth_feature_screen.dart';
import 'package:app/features/auth/presentation/pages/code_screen.dart';
import 'package:app/features/auth/presentation/pages/phone_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

// Welcome, phone number and code share one SignInCubit, so the code page
// knows the number. The cubit is closed when the user leaves these pages.
ShellRoute signInShell() => ShellRoute(
  pageBuilder: iosShellPage(
    (context, state, child) => BlocProvider(
      create: (context) => SignInCubit(GetIt.I<AuthUseCase>()),
      child: child,
    ),
  ),
  routes: <RouteBase>[
    GoRoute(
      path: Routes.auth,
      redirect: _welcomeOnce,
      pageBuilder: iosPage((context, state) => const AuthFeatureScreen()),
    ),
    GoRoute(
      path: Routes.authPhone,
      pageBuilder: iosPage((context, state) => const PhoneScreen()),
    ),
    GoRoute(
      path: Routes.authCode,
      pageBuilder: iosPage((context, state) => const CodeScreen()),
    ),
  ],
);

/// The welcome shows once per install ([WelcomeMemory]). After it, a
/// signed-out phone opens on the phone number page, and what was the last
/// person's goes, as the welcome would have removed it.
Future<String?> _welcomeOnce(BuildContext context, GoRouterState state) async {
  if (!await GetIt.I<WelcomeMemory>().seen()) return null;
  unawaited(forgetSignedOutPerson());
  return Routes.authPhone;
}
