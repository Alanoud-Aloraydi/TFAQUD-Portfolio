import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// The month «السجل» shows and its readings: the patient's current month at
/// first, in the calendar chosen in «حسابي», read again when the circle or
/// the calendar changes; never a month ahead of it.
mixin MeasurementRecordMonth on State<MeasurementRecordSection> {
  // A saved photo anywhere, or «السجل» pulled down, reads it again quietly.
  late final MeasurementReadingsCubit readings = MeasurementReadingsCubit(
    GetIt.I<MeasurementsUseCase>(),
    RefreshScope.withPulls(context, GetIt.I<PrivatePhotoRepository>().changes),
  );

  /// The month shown; the patient's current one at first.
  late CalendarMonth month = thisMonth;
  bool _started = false;

  DateTime get _today => PatientClockScope.of(context).today();
  DateCalendar get _calendar => CalendarScope.of(context);

  CalendarMonth get thisMonth => CalendarMonth.of(_today, _calendar);

  /// The first month is read here, not in initState: the patient's month.
  /// Another calendar starts again on this month, in it.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started && month.calendar == _calendar) return;
    if (_started) month = thisMonth;
    _started = true;
    loadMonth();
  }

  @override
  void didUpdateWidget(MeasurementRecordSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.circleId != oldWidget.circleId) loadMonth();
  }

  @override
  void dispose() {
    readings.close();
    super.dispose();
  }

  void loadMonth() => readings.load(widget.circleId, month.first, month.last);

  void changeMonth(int offset) {
    final CalendarMonth candidate = month.shift(offset);
    if (candidate.isAfter(thisMonth)) return;
    setState(() => month = candidate);
    loadMonth();
  }
}

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
