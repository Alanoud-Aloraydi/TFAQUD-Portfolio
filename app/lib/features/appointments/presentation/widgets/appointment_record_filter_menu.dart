import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/features/appointments/presentation/appointment_record_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The menu that narrows «السجل» to one kind of its visits.
class AppointmentRecordFilterMenu extends StatelessWidget {
  const AppointmentRecordFilterMenu({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AppointmentRecordFilter selected;
  final ValueChanged<AppointmentRecordFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return WhiteFilterMenu<AppointmentRecordFilter>(
      options: <AppointmentRecordFilter, String>{
        for (final AppointmentRecordFilter value
            in AppointmentRecordFilter.values)
          value: context.tr(value.labelKey),
      },
      selected: selected,
      onChanged: onChanged,
    );
  }
}
