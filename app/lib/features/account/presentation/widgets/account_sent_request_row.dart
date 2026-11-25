import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/request_age.dart';
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
    final bool accepted = request.status == CircleRequestStatus.accepted;
    final int? days = RequestAge.days(
      request.createdAt,
      PatientClockScope.of(context),
    );
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: MergeSemantics(
              child: Row(
                children: <Widget>[
                  const SentRequestIcon(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SentRequestTexts(request: request, days: days),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SentRequestPill(accepted: accepted),
                  const SizedBox(width: AppSpacing.xs),
                  // Mirrored on a right-to-left screen: it points to the end of the row.
                  Icon(ArrowIcons.forward, color: context.tokens.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The phone in a circle at the start of a sent request's row.
class SentRequestIcon extends StatelessWidget {
  const SentRequestIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppSemanticColors.selectedSurface,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        PeopleIcons.phone,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.textPrimary,
      ),
    );
  }
}

/// The number a request was sent to, and under it how long ago, when the
/// age is known.
class SentRequestTexts extends StatelessWidget {
  const SentRequestTexts({
    super.key,
    required this.request,
    required this.days,
  });

  final SentCircleRequest request;
  final int? days;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int? age = days;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          SaudiMobile.display(request.patientPhoneNumber),
          textDirection: TextDirection.ltr,
          style: text.titleMedium,
        ),
        if (age != null)
          Text(
            _ageText(context, age),
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
      ],
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

/// Where a sent request stands, short enough for its row: accepted or
/// still pending.
class SentRequestPill extends StatelessWidget {
  const SentRequestPill({super.key, required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      icon: accepted ? ActionIcons.check : ScheduleIcons.clock,
      text: context.tr(
        accepted
            ? 'account.status_accepted_short'
            : 'circles.request_status_pending',
      ),
      background: AppSemanticColors.background,
      foreground: accepted
          ? AppSemanticColors.statusSuccess
          : context.tokens.textSecondary,
    );
  }
}
