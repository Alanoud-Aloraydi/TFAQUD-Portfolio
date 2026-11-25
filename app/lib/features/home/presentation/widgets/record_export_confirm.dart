import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows what the file will hold before it is created. True when the person
/// agrees.
Future<bool?> showRecordExportConfirm(
  BuildContext context,
  RecordExportData data,
) {
  final int missed = data.missedDoses.length;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.tr('record_export.preview_title')),
      content: Text(
        context.tr(
          'record_export.preview_text',
          args: <String>[
            '${data.currentMedications}',
            '${data.doses.where((d) => d.record != null).length}',
            '$missed',
            '${data.takenReadings.length}',
            '${data.appointments.length}',
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr('record_export.create_file')),
        ),
      ],
    ),
  );
}

/// The app's own date wheel, twice: where the period starts, then where it
/// ends (never before its start, never after [today]). [current] is the
/// period chosen so far, which the wheels open on. Null when either wheel
/// is closed without a choice.
Future<ExportPeriod?> pickCustomExportPeriod(
  BuildContext context, {
  required ExportPeriod Function() current,
  required DateTime today,
}) async {
  final DateTime? start = await showTafaqodDateSheet(
    context,
    title: context.tr('record_export.custom_start'),
    initialDate: current().start,
    firstDate: DateTime(2000),
    lastDate: today,
    confirmLabel: context.tr('common.continue'),
  );
  if (start == null || !context.mounted) return null;
  final DateTime end0 = current().end.isBefore(start) ? start : current().end;
  final DateTime? end = await showTafaqodDateSheet(
    context,
    title: context.tr('record_export.custom_end'),
    initialDate: end0.isAfter(today) ? today : end0,
    firstDate: start,
    lastDate: today,
  );
  if (end == null) return null;
  return ExportPeriod(start, end);
}
