import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// «ذكّرني لاحقًا»; «بنذكّرك 2:36 م» while this phone put the dose off
/// ([at]); «مؤجّلة إلى 2:36 م، لين» while someone else did ([shared]).
String doseSnoozeLabel(
  BuildContext context,
  DateTime? at,
  SharedSnooze? shared,
) {
  String clock(DateTime moment) =>
      wallTimeText(PatientClockScope.of(context).wallTime(moment));
  if (at != null) {
    return context.tr('reminders.snoozed', args: <String>[clock(at)]);
  }
  if (shared != null) {
    final String? name = shared.byName;
    return name == null
        ? context.tr(
            'reminders.snoozed_shared',
            args: <String>[clock(shared.remindAt)],
          )
        : context.tr(
            'reminders.snoozed_by',
            args: <String>[clock(shared.remindAt), name],
          );
  }
  return context.tr('reminders.snooze');
}

/// A filled bell once the dose is put off, an outline one before that.
IconData doseSnoozeIcon(DateTime? at, SharedSnooze? shared) =>
    at == null && shared == null
    ? CupertinoIcons.bell
    : CupertinoIcons.bell_fill;
