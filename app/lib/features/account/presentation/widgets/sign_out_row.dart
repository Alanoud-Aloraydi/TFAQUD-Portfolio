import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The "تسجيل الخروج" row. It needs an [AuthCubit] above it. The tokens are
/// removed from the phone even when the server cannot be reached.
class SignOutRow extends StatelessWidget {
  const SignOutRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (BuildContext context, AuthState state) {
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
      builder: (BuildContext context, AuthState state) {
        return ActionRow(
          label: context.tr('auth.sign_out'),
          color: AppColors.brand,
          busy: state is AuthLoadingState,
          onPressed: () => context.read<AuthCubit>().signOut(),
        );
      },
    );
  }
}
