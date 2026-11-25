import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/request_age.dart';
import 'package:app/features/circles/presentation/widgets/invitation_actions.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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
