import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_alert.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SimplifiedSignOutButton extends StatelessWidget {
  const SimplifiedSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          AppToast.show(context, state.messageKey, kind: ToastKind.error);
        }
        if (state is AuthSignedOutState) {
          if (!state.serverConfirmed) {
            AppToast.show(
              context,
              'auth.sign_out_local_only',
              kind: ToastKind.error,
            );
          }
          context.go(Routes.auth);
        }
      },
      builder: (context, state) => SimplifiedOutlinedDanger(
        label: context.tr('simplified_mode.sign_out'),
        busy: state is AuthLoadingState,
        filled: true,
        onPressed: () => _signOut(context),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (await askSignOutConfirmation(context) != true) return;
    if (!context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }
}
