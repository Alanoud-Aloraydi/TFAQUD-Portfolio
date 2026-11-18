import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_section.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// The month «السجل» shows and its readings: the patient's current month at
/// first, read again when the circle changes; never a month ahead of it.
mixin MeasurementRecordMonth on State<MeasurementRecordSection> {
  // A saved photo anywhere, or «السجل» pulled down, reads it again quietly.
  late final MeasurementReadingsCubit readings = MeasurementReadingsCubit(
    GetIt.I<MeasurementsUseCase>(),
    RefreshScope.withPulls(context, GetIt.I<PrivatePhotoRepository>().changes),
  );

  /// The month shown; the patient's current one at first.
  late DateTime month = thisMonth;
  bool _started = false;

  DateTime get thisMonth {
    final DateTime today = PatientClockScope.of(context).today();
    return DateTime(today.year, today.month);
  }

  /// The first month is read here, not in initState: the patient's month.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
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

  void loadMonth() {
    final DateTime end = DateTime(month.year, month.month + 1, 0);
    readings.load(widget.circleId, month, end);
  }

  void changeMonth(int offset) {
    final DateTime candidate = DateTime(month.year, month.month + offset);
    if (candidate.isAfter(thisMonth)) return;
    setState(() => month = candidate);
    loadMonth();
  }
}
