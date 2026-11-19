import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:app/features/measurements/presentation/measurement_record_filter.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_content.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_filter_menu.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_month.dart';
import 'package:app/features/measurements/presentation/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «السجل»'s read-only readings of [circleId], a month at a time, through
/// its own [MeasurementReadingsCubit], which reads again by itself when a
/// reading of the circle is saved anywhere. Unrecorded times stay on «اليوم».
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

class _MeasurementRecordSectionState extends State<MeasurementRecordSection>
    with MeasurementRecordMonth {
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
              MeasurementRecordFilterMenu(
                selected: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: AppSpacing.md),
              MonthSwitcher(
                month: month,
                canGoForward: month != thisMonth,
                onChange: changeMonth,
              ),
              const SizedBox(height: AppSpacing.md),
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
}
