import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<DateTime?> selectTakenTime(
  BuildContext context,
  DateTime scheduledOn,
) async {
  final now = DateTime.now();
  final selected = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now),
    helpText: context.tr('medications.actual_time'),
    cancelText: context.tr('common.cancel'),
    confirmText: context.tr('common.confirm'),
  );
  if (selected == null) return null;
  return DateTime(
    scheduledOn.year,
    scheduledOn.month,
    scheduledOn.day,
    selected.hour,
    selected.minute,
  );
}

Future<bool> confirmSkippedDose(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('medications.skip_title')),
          content: Text(context.tr('medications.skip_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('medications.skip_confirm')),
            ),
          ],
        ),
      ) ??
      false;
}
