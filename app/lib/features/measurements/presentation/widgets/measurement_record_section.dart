import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_loading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// «السجل»'s read-only readings of [circleId], a month at a time, through
/// its own [MeasurementReadingsCubit], which reads again by itself when a
/// reading of the circle is saved anywhere. Unrecorded times stay on «اليوم».
/// With nothing saved yet, only the empty note shows: no month bar or
/// filter.
class MeasurementRecordSection extends StatefulWidget {
  const MeasurementRecordSection({
    super.key,
    required this.circleId,
    required this.header,
    this.onAddReading,
  });

  final String circleId;
  final Widget header;

  /// Opens the reading sheet from the empty note; null hides it.
  final VoidCallback? onAddReading;

  @override
  State<MeasurementRecordSection> createState() =>
      _MeasurementRecordSectionState();
}

class _MeasurementRecordSectionState extends State<MeasurementRecordSection> {
  MeasurementRecordFilter _filter = MeasurementRecordFilter.all;

  @override
  Widget build(BuildContext context) =>
      BlocProvider<MeasurementReadingsCubit>.value(
        value: readings,
        child: BlocBuilder<MeasurementReadingsCubit, MeasurementReadingsState>(
          builder: (context, state) => ListView(
            padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
            children: <Widget>[
              widget.header,
              const SizedBox(height: AppSpacing.md),
              if (showsMonths(shown: state.readings.isNotEmpty)) ...<Widget>[
                MeasurementRecordFilterMenu(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: AppSpacing.md),
                MonthSwitcher(
                  month: month,
                  canGoForward: month != thisMonth,
                  canGoBack: canGoBack(month),
                  onChange: changeMonth,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ...measurementRecordContent(
                state,
                circleId: widget.circleId,
                month: month,
                filter: _filter,
                onRetry: loadMonth,
                onAddReading: widget.onAddReading,
              ),
            ],
          ),
        ),
      );

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
    loadMonth();
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

/// The month name with arrows to move between months. The forward arrow is
/// off on the current month: there is nothing to read after it; the back
/// arrow on the first month with something to read.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.canGoForward,
    required this.onChange,
    this.canGoBack = true,
  });

  final CalendarMonth month;
  final bool canGoForward;
  final bool canGoBack;

  /// Called with -1 for the month before, 1 for the month after.
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: context.tr('measurements.previous_month'),
          onPressed: canGoBack ? () => onChange(-1) : null,
          icon: const Icon(CupertinoIcons.chevron_right),
        ),
        Expanded(
          child: Text(
            calendarMonthTitle(context, month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: context.tr('measurements.next_month'),
          onPressed: canGoForward ? () => onChange(1) : null,
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
      ],
    );
  }
}
