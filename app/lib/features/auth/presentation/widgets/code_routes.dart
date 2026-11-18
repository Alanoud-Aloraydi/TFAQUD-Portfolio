import 'package:app/core/navigation/routers.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Back from the code page to the phone number.
void leaveCodePage(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    // Opened directly (a reload on the web): there is no page to return to.
    context.read<SignInCubit>().backToPhone();
    context.go(Routes.authPhone);
  }
}

/// Where a verified sign-in goes: a user who has not saved the name page
/// goes to it; the others go home, to whichever home their account's app
/// mode uses.
void goSignedIn(BuildContext context, SignInState state) {
  context.go(
    state.needsProfile
        ? Routes.onboarding
        : state.appMode == CircleAppMode.simplified
        ? Routes.simplifiedMode
        : Routes.today,
  );
}
