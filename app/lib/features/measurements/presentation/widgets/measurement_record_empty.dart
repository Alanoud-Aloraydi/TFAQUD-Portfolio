import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «السجل»'s readings when the month has none under the filter: the note,
/// with «تسجيل قراءة» for someone who may record one, as «الخطة» offers
/// its own add.
class MeasurementRecordEmpty extends StatelessWidget {
  const MeasurementRecordEmpty({super.key, this.onAdd});

  /// Opens the reading sheet; null hides the action.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('measurements.no_records'),
    actionLabel: onAdd == null
        ? null
        : context.tr('measurements.record_reading'),
    onAction: onAdd,
  );
}
