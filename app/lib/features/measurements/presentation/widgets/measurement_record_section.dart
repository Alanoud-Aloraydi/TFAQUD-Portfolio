import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/section_header.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_list.dart';
import 'package:app/features/measurements/presentation/widgets/month_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The «السجل» tab's read-only measurements: a month's charts, calendar
/// and readings of [circleId]. Scheduled times nobody recorded stay on
/// «اليوم», not here.
///
/// Holds its own [MeasurementReadingsCubit] for the month shown; it reads
/// again by itself when a reading of the circle is saved anywhere.
class MeasurementRecordSection extends StatefulWidget {
  const MeasurementRecordSection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
  final Widget header;

  @override
  State<MeasurementRecordSection> createState() =>
      _MeasurementRecordSectionState();
}

class _MeasurementRecordSectionState extends State<MeasurementRecordSection> {
  late final MeasurementReadingsCubit _readings = MeasurementReadingsCubit(
    GetIt.I<MeasurementRepository>(),
    GetIt.I<PrivatePhotoRepository>().changes,
  );

  /// The month shown; the patient's current one at first.
  late DateTime _month = _thisMonth;
  String _filter = 'all';
  bool _started = false;

  DateTime get _thisMonth {
    final DateTime today = PatientClockScope.of(context).today();
    return DateTime(today.year, today.month);
  }

  /// The first month is read here, not in initState: it is the patient's
  /// current month, read from [PatientClockScope].
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadMonth();
  }

  @override
  void didUpdateWidget(MeasurementRecordSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.circleId != oldWidget.circleId) _loadMonth();
  }

  @override
  void dispose() {
    _readings.close();
    super.dispose();
  }

  void _loadMonth() {
    final DateTime end = DateTime(_month.year, _month.month + 1, 0);
    _readings.load(widget.circleId, _month, end);
  }

  void _changeMonth(int offset) {
    final DateTime candidate = DateTime(_month.year, _month.month + offset);
    if (candidate.isAfter(_thisMonth)) return;
    setState(() => _month = candidate);
    _loadMonth();
  }

  bool _matches(MeasurementKind kind) =>
      _filter == 'all' || kind.name == _filter;

  @override
  Widget build(BuildContext context) =>
      BlocProvider<MeasurementReadingsCubit>.value(
        value: _readings,
        child: BlocBuilder<MeasurementReadingsCubit, MeasurementReadingsState>(
          builder: (context, state) => ListView(
            padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
            children: <Widget>[
              widget.header,
              const SizedBox(height: AppSpacing.md),
              WhiteFilterMenu<String>(
                options: <String, String>{
                  'all': context.tr('measurements.all'),
                  'glucose': context.tr('measurements.glucose'),
                  'bp': context.tr('measurements.bp'),
                },
                selected: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: AppSpacing.md),
              MonthSwitcher(
                month: _month,
                canGoForward: _month != _thisMonth,
                onChange: _changeMonth,
              ),
              const SizedBox(height: AppSpacing.md),
              ..._content(context, state),
            ],
          ),
        ),
      );

  List<Widget> _content(BuildContext context, MeasurementReadingsState state) {
    if (state.status == MeasurementLoadStatus.loading &&
        state.readings.isEmpty) {
      return const <Widget>[Center(child: CircularProgressIndicator())];
    }
    if (state.status == MeasurementLoadStatus.failure) {
      return <Widget>[
        RetryView(
          messageKey: state.errorKey ?? 'error.unknown',
          onRetry: _loadMonth,
        ),
      ];
    }
    return _loaded(context, state);
  }

  List<Widget> _loaded(BuildContext context, MeasurementReadingsState state) {
    final List<MeasurementReading> values = <MeasurementReading>[
      for (final MeasurementReading r in state.readings)
        if (r.outcome == 'read') r,
    ];
    return <Widget>[
      for (final MeasurementKind kind in MeasurementKind.values)
        if (_matches(kind)) ...<Widget>[
          MeasurementChartCard(
            kind: kind,
            readings: <MeasurementReading>[
              for (final MeasurementReading r in values)
                if (r.kind == kind) r,
            ],
            month: _month,
            circleId: widget.circleId,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      const SizedBox(height: AppSpacing.md),
      SectionHeader(context.tr('measurements.readings')),
      const SizedBox(height: AppSpacing.sm),
      MeasurementReadingsList(
        circleId: widget.circleId,
        readings: <MeasurementReading>[
          for (final MeasurementReading r in state.readings)
            if (_matches(r.kind)) r,
        ],
      ),
    ];
  }
}
