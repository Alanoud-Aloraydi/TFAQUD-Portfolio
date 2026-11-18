import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/core/widgets/overlays/skip_reason_body.dart';
import 'package:app/core/widgets/overlays/skip_reason_option.dart';
import 'package:flutter/material.dart';

export 'package:app/core/widgets/overlays/skip_reason_option.dart';

/// The one sheet that skips a dose or a reading: the question as its
/// [title], «(اختياري)» under it ([message]), the [reasons] with a check
/// on the chosen one, a row to write «سبب آخر» in, and [confirmLabel]. Returns
/// null when the person closes it.
Future<SkipReasonChoice?> showSkipReasonSheet(
  BuildContext context, {
  required String title,
  required String message,
  required List<SkipReasonOption> reasons,
  required String noteLabel,
  required String confirmLabel,
}) => showGlassSheet<SkipReasonChoice>(
  context,
  title: title,
  message: message,
  builder: (_) => SkipReasonBody(
    reasons: reasons,
    noteLabel: noteLabel,
    confirmLabel: confirmLabel,
  ),
);
