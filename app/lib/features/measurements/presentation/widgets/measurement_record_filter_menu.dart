import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/features/measurements/presentation/measurement_record_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Which measurements «السجل» shows: all, or one kind.
class MeasurementRecordFilterMenu extends StatelessWidget {
  const MeasurementRecordFilterMenu({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MeasurementRecordFilter selected;
  final ValueChanged<MeasurementRecordFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return WhiteFilterMenu<MeasurementRecordFilter>(
      options: <MeasurementRecordFilter, String>{
        for (final MeasurementRecordFilter value
            in MeasurementRecordFilter.values)
          value: context.tr(value.labelKey),
      },
      selected: selected,
      onChanged: onChanged,
    );
  }
}
