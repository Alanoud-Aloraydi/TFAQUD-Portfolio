import 'package:app/app/router/routers.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_alert.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Three big tiles, each showing «أ» at the size it gives.
class SimplifiedTextSizeCard extends StatelessWidget {
  const SimplifiedTextSizeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final SimplifiedTextSize selected = context
        .select<SimplifiedSettingsCubit, SimplifiedTextSize>(
          (cubit) => cubit.state.textSize,
        );
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.text_size'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final SimplifiedTextSize size
                  in SimplifiedTextSize.values) ...<Widget>[
                if (size != SimplifiedTextSize.normal)
                  const SizedBox(width: 10),
                Expanded(
                  child: SimplifiedTextSizeTile(
                    size: size,
                    selected: size == selected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

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
