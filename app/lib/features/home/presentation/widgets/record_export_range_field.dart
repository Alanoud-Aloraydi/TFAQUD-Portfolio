import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The period picker: a ready-made span, or the person's own dates.
class RecordExportRangeField extends StatelessWidget {
  const RecordExportRangeField({
    super.key,
    required this.range,
    required this.custom,
    required this.onSelected,
  });

  final ExportRange range;
  final ExportPeriod? custom;
  final ValueChanged<ExportRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExportRange>(
      initialValue: range,
      decoration: InputDecoration(
        labelText: context.tr('record_export.period'),
      ),
      items: <DropdownMenuItem<ExportRange>>[
        for (final ExportRange value in ExportRange.values)
          DropdownMenuItem(value: value, child: Text(_label(context, value))),
      ],
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
    );
  }

  String _label(BuildContext context, ExportRange value) {
    final ExportPeriod? own = custom;
    if (value == ExportRange.custom && own != null) {
      return '${formatBirthDate(context, own.start)} – '
          '${formatBirthDate(context, own.end)}';
    }
    return context.tr('record_export.range.${value.name}');
  }
}
