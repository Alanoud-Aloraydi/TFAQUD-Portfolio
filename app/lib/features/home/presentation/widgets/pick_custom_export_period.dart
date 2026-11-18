import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
