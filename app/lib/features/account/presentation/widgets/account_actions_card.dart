import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/action_row.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_alert.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The last card of «حسابي»: signing out, and deleting the account.
Widget accountActionsCard(
  BuildContext context, {
  required AccountCubit cubit,
  required bool deleting,
}) {
  return SettingsCard(
    children: <Widget>[
      const SignOutRow(),
      ActionRow(
        label: context.tr('account.delete_account'),
        color: AppSemanticColors.statusError,
        busy: deleting,
        onPressed: cubit.startDelete,
      ),
    ],
  );
}

/// The "تسجيل الخروج" row. It needs an [AuthCubit] above it. The tokens are
/// removed from the phone even when the server cannot be reached.
class SignOutRow extends StatelessWidget {
  const SignOutRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (BuildContext context, AuthState state) {
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
      builder: (BuildContext context, AuthState state) {
        return ActionRow(
          label: context.tr('auth.sign_out'),
          // Signing out is a destructive action: the error red.
          color: AppSemanticColors.statusError,
          busy: state is AuthLoadingState,
          onPressed: () => _signOut(context),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (await askSignOutConfirmation(context) != true) return;
    if (!context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }
}
