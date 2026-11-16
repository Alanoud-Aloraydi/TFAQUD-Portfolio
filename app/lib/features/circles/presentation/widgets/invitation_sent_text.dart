import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
