import 'package:app/app/router/routers.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/ltr_isolate.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The wait before a new code, or «إعادة الإرسال» once it is over.
class CodeResendLine extends StatelessWidget {
  const CodeResendLine({super.key, required this.resendSeconds});

  final int resendSeconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: resendSeconds > 0
          ? Text(
              context.tr(
                'auth.resend_in',
                args: <String>[ltrIsolate(waitClock(resendSeconds))],
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : TextButton(
              onPressed: context.read<SignInCubit>().resendCode,
              child: Text(context.tr('auth.resend')),
            ),
    );
  }
}

/// [seconds] as minutes and seconds, such as 1:05.
String waitClock(int seconds) {
  final String minutes = (seconds ~/ 60).toString();
  final String rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

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
