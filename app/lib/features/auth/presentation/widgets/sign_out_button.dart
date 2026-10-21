import 'package:app/core/navigation/routers.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Sign-out button. It needs an [AuthCubit] above it in the widget tree.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr(state.messageKey))));
        }
        if (state is AuthSignedOutState) {
          if (!state.serverConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('auth.sign_out_local_only'))),
            );
          }
          context.go(Routes.auth);
        }
      },
      builder: (context, state) {
        final bool busy = state is AuthLoadingState;
        return FilledButton.icon(
          onPressed: busy ? null : () => context.read<AuthCubit>().signOut(),
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(context.tr('auth.sign_out')),
        );
      },
    );
  }
}
