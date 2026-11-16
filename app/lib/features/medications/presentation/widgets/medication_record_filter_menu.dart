import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/features/medications/presentation/medication_record_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Which medicines «السجل» shows: all of them, or one state of a plan.
class MedicationRecordFilterMenu extends StatelessWidget {
  const MedicationRecordFilterMenu({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final MedicationRecordFilter filter;
  final ValueChanged<MedicationRecordFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return WhiteFilterMenu<MedicationRecordFilter>(
      options: <MedicationRecordFilter, String>{
        for (final MedicationRecordFilter value
            in MedicationRecordFilter.values)
          value: context.tr(value.labelKey),
      },
      selected: filter,
      onChanged: onChanged,
    );
  }
}
