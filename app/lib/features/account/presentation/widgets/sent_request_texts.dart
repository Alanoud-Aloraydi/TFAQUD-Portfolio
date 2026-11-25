import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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
