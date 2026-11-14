import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/request_age.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// One circle that waits for the patient: the number it was sent to, how
/// long ago, and where it stands. The circle has no name yet: the patient
/// names it when they complete the request.
class AccountSentRequestRow extends StatelessWidget {
  const AccountSentRequestRow({
    super.key,
    required this.request,
    required this.onTap,
  });

  final SentCircleRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool accepted = request.status == CircleRequestStatus.accepted;
    final int? days = RequestAge.days(
      request.createdAt,
      PatientClockScope.of(context),
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: AppSizes.avatar,
              height: AppSizes.avatar,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppSemanticColors.selectedSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.phone,
                size: AppSizes.iconSmall,
                color: AppSemanticColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    SaudiMobile.display(request.patientPhoneNumber),
                    textDirection: TextDirection.ltr,
                    style: text.titleMedium,
                  ),
                  if (days != null)
                    Text(
                      _ageText(context, days),
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusPill(
              icon: accepted ? AppIcons.check : AppIcons.clock,
              text: context.tr(
                accepted
                    ? 'account.status_accepted_short'
                    : 'circles.request_status_pending',
              ),
              background: AppSemanticColors.background,
              foreground: accepted
                  ? AppSemanticColors.statusSuccess
                  : context.tokens.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            // Mirrored on a right-to-left screen: it points to the end of the row.
            Icon(AppIcons.forward, color: context.tokens.textSecondary),
          ],
        ),
      ),
    );
  }

  /// "أُرسل الطلب اليوم", "قبل يومين", "قبل 5 أيام". The number is written 0-9.
  String _ageText(BuildContext context, int days) {
    if (days == 0) return context.tr('account.sent_today');
    if (days == 1) return context.tr('account.sent_yesterday');
    if (days == 2) return context.tr('account.sent_two_days');
    return context.tr(
      days <= 10 ? 'account.sent_days_few' : 'account.sent_days_many',
      args: <String>['$days'],
    );
  }
}
