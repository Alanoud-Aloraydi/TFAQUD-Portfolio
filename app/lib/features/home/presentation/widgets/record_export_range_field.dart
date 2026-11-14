import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الفترة»: a row that opens the glass menu of the ready-made spans and
/// «فترة مخصصة», like every other menu of the app.
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
    return InsetGroup(
      children: <Widget>[
        Builder(
          builder: (BuildContext anchor) => InsetRow(
            label: context.tr('record_export.period'),
            value: _label(context, range),
            showChevron: true,
            onTap: () => _open(anchor),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext anchor) async {
    final ExportRange? picked = await showGlassMenu<ExportRange>(
      anchorContext: anchor,
      semanticLabel: anchor.tr('record_export.period'),
      sections: <List<GlassMenuItem<ExportRange>>>[
        <GlassMenuItem<ExportRange>>[
          for (final ExportRange value in ExportRange.values)
            GlassMenuItem<ExportRange>(
              value: value,
              label: anchor.tr('record_export.range.${value.name}'),
              selected: value == range,
            ),
        ],
      ],
    );
    if (picked != null) onSelected(picked);
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
