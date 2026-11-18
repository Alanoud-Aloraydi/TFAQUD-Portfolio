import 'dart:async';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_error_state.dart';
import 'package:app/features/auth/presentation/cubit/auth_signed_out_state.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Where the name step goes: on to the start step, back to the phone number
/// signed out, or to the sign-in when it ended.
mixin ProfileStepLeaving<T extends StatefulWidget> on State<T> {
  Future<void> continueToStart() async {
    final bool saved = await context.read<OnboardingCubit>().saveProfile();
    if (!saved || !mounted) return;
    AppToast.show(context, 'toast.profile_saved');
    unawaited(context.push(Routes.onboardingStart));
  }

  /// «رجوع»: the sign-in is already made with the code, so going back to
  /// the phone number (to correct it) ends it. A new code is needed to come
  /// back, so the person confirms first.
  Future<void> confirmBack() async {
    final bool? leave = await showAppAlert<bool>(
      context,
      title: context.tr('onboarding.back_title'),
      message: context.tr('onboarding.back_message'),
      actions: <AppAlertAction<bool>>[
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('common.back'),
          value: true,
          primary: true,
        ),
      ],
    );
    if (leave == true && mounted) {
      unawaited(context.read<AuthCubit>().signOut());
    }
  }

  /// Leaves for the phone number page once the sign-out is done, or shows
  /// why it failed.
  void signedOut(BuildContext context, AuthState state) {
    if (state is AuthErrorState) {
      AppToast.show(context, state.messageKey, kind: ToastKind.error);
      return;
    }
    if (state is AuthSignedOutState) {
      unawaited(forgetSignedOutPerson());
      context.go(Routes.authPhone);
    }
  }

  /// The save found the sign-in ended (revoked or expired): nothing of the
  /// person stays on the phone, and the sign-in starts again.
  void sessionEnded(BuildContext context, OnboardingState state) {
    unawaited(forgetSignedOutPerson());
    context.go(Routes.auth);
  }
}
