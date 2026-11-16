import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/circle_pending_invitation.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_small_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «إعادة الإرسال» and «إلغاء» under a waiting invitation. Both are off
/// while another change of the members is still going through.
class InvitationActions extends StatelessWidget {
  const InvitationActions({super.key, required this.invitation});

  final CirclePendingInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    // One change of the members at a time (CircleOverviewState.acting).
    final bool acting = context.select(
      (CircleOverviewCubit tab) => tab.state.acting,
    );
    return Wrap(
      spacing: AppSpacing.sm,
      children: <Widget>[
        CircleSmallAction(
          label: context.tr('circle_overview.resend'),
          color: AppSemanticColors.textPrimary,
          enabled: !acting,
          onPressed: () => _act(
            context,
            cubit.resendInvitation(invitation.id),
            'toast.invite_resent',
          ),
        ),
        CircleSmallAction(
          label: context.tr('common.cancel'),
          color: AppSemanticColors.statusError,
          enabled: !acting,
          onPressed: () => _act(
            context,
            cubit.cancelInvitation(invitation.id),
            'toast.invite_canceled',
          ),
        ),
      ],
    );
  }
}

Future<void> _act(
  BuildContext context,
  Future<String?> action,
  String doneKey,
) async {
  final String? errorKey = await action;
  if (!context.mounted) return;
  AppToast.show(
    context,
    errorKey ?? doneKey,
    kind: errorKey == null ? ToastKind.success : ToastKind.error,
  );
}
