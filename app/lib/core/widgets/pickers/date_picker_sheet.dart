import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/core/widgets/pickers/date_wheel_sheet.dart';
import 'package:flutter/material.dart';

export 'package:app/core/widgets/pickers/date_wheel_sheet.dart';

/// Opens the app's one date picker, in a glass sheet: an iOS wheel of day,
/// month and year with one selection band across the row. Returns the confirmed date, or null
/// when the sheet is closed without confirming.
///
/// [confirmLabel] defaults to «تأكيد».
Future<DateTime?> showTafaqodDateSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? confirmLabel,
}) => showGlassSheet<DateTime>(
  context,
  title: title,
  builder: (_) => DateWheelSheet(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    confirmLabel: confirmLabel,
  ),
);
