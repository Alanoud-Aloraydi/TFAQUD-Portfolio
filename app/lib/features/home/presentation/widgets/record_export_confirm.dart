import 'package:app/features/home/domain/record_export_data.dart';
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
