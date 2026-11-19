import 'package:app/core/utils/calendar_month.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_section.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// The patient's first day with a saved reading, read with the circle:
/// «السجل» shows no month bar or filter before there is one, and goes back
/// no further than its month, in either calendar.
mixin MeasurementRecordFirst on State<MeasurementRecordSection> {
  DateTime? _firstDay;

  /// When it could not be read, the bar shows with no limit, as before.
  bool _firstFailed = false;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  // Another circle: built again right after, with nothing known of it.
  @override
  void didUpdateWidget(MeasurementRecordSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.circleId == oldWidget.circleId) return;
    _firstDay = null;
    _firstFailed = false;
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    final String circleId = widget.circleId;
    try {
      final DateTime? day = await GetIt.I<MeasurementsUseCase>().firstReadingOn(
        circleId,
      );
      if (!mounted || circleId != widget.circleId) return;
      setState(() {
        _firstFailed = false;
        _firstDay = day;
      });
    } catch (_) {
      if (mounted && circleId == widget.circleId) {
        setState(() => _firstFailed = true);
      }
    }
  }

  /// [shown] readings mean something was saved, even after the first month
  /// was read (the first reading was just recorded).
  bool showsMonths({required bool shown}) =>
      shown || _firstFailed || _firstDay != null;

  bool canGoBack(CalendarMonth month) {
    final DateTime? first = _firstDay;
    return _firstFailed ||
        (first != null &&
            month.isAfter(CalendarMonth.of(first, month.calendar)));
  }
}
