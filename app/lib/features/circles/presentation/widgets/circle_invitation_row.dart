import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/request_age.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile_content.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A pending invitation: the number left to right, how long ago it was
/// sent, and under them «إعادة الإرسال» and «إلغاء».
class CircleInvitationRow extends StatelessWidget {
  const CircleInvitationRow({
    super.key,
    required this.invitation,
    required this.canManage,
  });

  final CirclePendingInvitation invitation;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int days =
        RequestAge.days(invitation.sentAt, PatientClockScope.of(context)) ?? 0;
    final String waiting = context.tr('circle_overview.pending');
    final String sent = invitationSentText(context, days);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CircleRequestAvatar.waiting(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  SaudiMobile.display(invitation.phoneNumber),
                  textDirection: TextDirection.ltr,
                  style: text.titleSmall,
                ),
                Text(
                  '$waiting، $sent',
                  style: text.bodySmall,
                  semanticsLabel: spoken('$waiting، $sent'),
                ),
                if (canManage) InvitationActions(invitation: invitation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «أُرسلت اليوم», «أُرسلت قبل يومين», «أُرسلت قبل 5 أيام»: Arabic counts
/// the first two, the few and the many differently.
String invitationSentText(BuildContext context, int days) {
  if (days == 0) return context.tr('circle_overview.sent_today');
  if (days == 1) return context.tr('circle_overview.sent_yesterday');
  if (days == 2) return context.tr('circle_overview.sent_two_days');
  return context.tr(
    days <= 10
        ? 'circle_overview.sent_days_few'
        : 'circle_overview.sent_days_many',
    args: <String>['$days'],
  );
}

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

/// An hourglass portrait for pending invitations.
class CircleRequestAvatar extends StatelessWidget {
  const CircleRequestAvatar.waiting({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppSizes.avatar,
        height: AppSizes.avatar,
        alignment: Alignment.center,
        decoration: const ShapeDecoration(
          color: AppSemanticColors.surfaceAttention,
          shape: CircleBorder(),
        ),
        child: const Icon(
          PeopleIcons.hourglass,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.doseDueMarker,
        ),
      ),
    );
  }
}
