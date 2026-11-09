import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/section_header.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_visuals.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Displays the measurement record section UI.
class MeasurementRecordSection extends StatefulWidget {
  const MeasurementRecordSection({
    super.key,
    required this.circleId,
    required this.header,
    required this.plans,
    required this.refreshRevision,
  });

  final String circleId;
  final Widget header;
  final List<MeasurementPlan> plans;
  final int refreshRevision;

  @override
  State<MeasurementRecordSection> createState() =>
      _MeasurementRecordSectionState();
}

class _MeasurementRecordSectionState extends State<MeasurementRecordSection> {
  late final MeasurementReadingsCubit _readings = MeasurementReadingsCubit(
    GetIt.I<MeasurementRepository>(),
    GetIt.I<PrivatePhotoRepository>().changes,
  );
  DateTime _month = DateTime(riyadhToday().year, riyadhToday().month);
  String _filter = 'all';
  bool _calendarGlucose = false;
  bool _calendarBp = false;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  @override
  void didUpdateWidget(MeasurementRecordSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.circleId != oldWidget.circleId ||
        widget.refreshRevision != oldWidget.refreshRevision) {
      _loadMonth();
    }
  }

  @override
  void dispose() {
    _readings.close();
    super.dispose();
  }

  void _loadMonth() => _readings.load(
    widget.circleId,
    _month,
    DateTime(_month.year, _month.month + 1, 0),
  );

  void _changeMonth(int offset) {
    final candidate = DateTime(_month.year, _month.month + offset);
    if (candidate.isAfter(DateTime(riyadhToday().year, riyadhToday().month))) {
      return;
    }
    setState(() => _month = candidate);
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _readings,
    child: BlocBuilder<MeasurementReadingsCubit, MeasurementReadingsState>(
      builder: (context, state) {
        final values = state.readings
            .where((item) => item.outcome == 'read')
            .toList();
        final filtered = state.readings
            .where((item) => _filter == 'all' || item.kind.name == _filter)
            .toList();
        return ListView(
          padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
          children: [
            widget.header,
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(CupertinoIcons.chevron_right),
                ),
                Expanded(
                  child: Text(
                    '${context.tr('circles.months.${_month.month}')} '
                    '${_month.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed:
                      _month.year == riyadhToday().year &&
                          _month.month == riyadhToday().month
                      ? null
                      : () => _changeMonth(1),
                  icon: const Icon(CupertinoIcons.chevron_left),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.status == MeasurementLoadStatus.loading &&
                state.readings.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (state.status == MeasurementLoadStatus.failure)
              TextButton(
                onPressed: _loadMonth,
                child: Text(context.tr(state.errorKey ?? 'error.unknown')),
              )
            else ...[
              _chartCard(context, MeasurementKind.glucose, values),
              const SizedBox(height: AppSpacing.md),
              _chartCard(context, MeasurementKind.bp, values),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                context.tr('measurements.readings'),
                trailing: TextButton.icon(
                  onPressed: () => showMeasurementReadingSheet(context),
                  icon: const Icon(CupertinoIcons.add),
                  label: Text(context.tr('measurements.record_reading')),
                ),
              ),
              WhiteFilterMenu<String>(
                options: {
                  'all': context.tr('measurements.all'),
                  'glucose': context.tr('measurements.glucose'),
                  'bp': context.tr('measurements.bp'),
                },
                selected: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                Center(child: Text(context.tr('measurements.no_readings')))
              else
                for (final reading in filtered) ...[
                  _readingRow(context, reading),
                  const SizedBox(height: AppSpacing.xs),
                ],
            ],
          ],
        );
      },
    ),
  );

  Widget _chartCard(
    BuildContext context,
    MeasurementKind kind,
    List<MeasurementReading> all,
  ) {
    final readings = all.where((item) => item.kind == kind).toList();
    final plan = widget.plans
        .where((item) => item.kind == kind && item.stoppedAt == null)
        .firstOrNull;
    final version = plan?.version;
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    final firstReading = readings.firstOrNull;
    final sharedReadingTarget =
        firstReading != null &&
        readings.every(
          (reading) =>
              reading.glucoseLow == firstReading.glucoseLow &&
              reading.glucoseHigh == firstReading.glucoseHigh &&
              reading.systolicLimit == firstReading.systolicLimit &&
              reading.diastolicLimit == firstReading.diastolicLimit,
        );
    final readingTarget = sharedReadingTarget ? firstReading : null;
    final planTarget =
        readings.isEmpty &&
            version != null &&
            !version.effectiveFromOn.isAfter(monthEnd)
        ? version
        : null;
    final low = kind == MeasurementKind.glucose
        ? readingTarget?.glucoseLow ?? planTarget?.glucoseLow
        : readingTarget?.diastolicLimit ?? planTarget?.diastolicLimit;
    final high = kind == MeasurementKind.glucose
        ? readingTarget?.glucoseHigh ?? planTarget?.glucoseHigh
        : readingTarget?.systolicLimit ?? planTarget?.systolicLimit;
    final calendar = kind == MeasurementKind.glucose
        ? _calendarGlucose
        : _calendarBp;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  kind == MeasurementKind.glucose
                      ? CupertinoIcons.drop
                      : CupertinoIcons.heart,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr(
                      kind == MeasurementKind.glucose
                          ? 'measurements.glucose'
                          : 'measurements.bp',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (readings.isNotEmpty)
                  Text(
                    readings.first.valueText,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              readings.isEmpty
                  ? context.tr('measurements.no_readings')
                  : context.tr(
                      'measurements.reading_count',
                      args: [
                        '${readings.length}',
                        '${readings.where((r) => r.outsideTarget == true).length}',
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassSegmentedControl<bool>(
              segments: {
                false: context.tr('measurements.chart'),
                true: context.tr('measurements.calendar'),
              },
              selected: calendar,
              onChanged: (value) => setState(() {
                if (kind == MeasurementKind.glucose) {
                  _calendarGlucose = value;
                } else {
                  _calendarBp = value;
                }
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: AppMotion.branchEnterMilliseconds,
              ),
              reverseDuration: const Duration(
                milliseconds: AppMotion.branchExitMilliseconds,
              ),
              switchInCurve: AppMotion.branchEnter,
              switchOutCurve: AppMotion.easeIn,
              child: KeyedSubtree(
                key: ValueKey(calendar),
                child: calendar
                    ? MeasurementCalendar(readings: readings, month: _month)
                    : MeasurementChart(
                        kind: kind,
                        readings: readings,
                        month: _month,
                        targetLow: low,
                        targetHigh: high,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readingRow(BuildContext context, MeasurementReading reading) {
    final skipped = reading.outcome == 'skipped';
    final at = skipped ? reading.scheduledOn! : riyadhNow(reading.measuredAt!);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              reading.kind == MeasurementKind.glucose
                  ? CupertinoIcons.drop
                  : CupertinoIcons.heart,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      reading.kind == MeasurementKind.glucose
                          ? 'measurements.glucose'
                          : 'measurements.bp',
                    ),
                  ),
                  Text(
                    skipped
                        ? '${at.day}/${at.month}/${at.year}'
                        : '${at.day}/${at.month}/${at.year} · '
                              '${at.hour.toString().padLeft(2, '0')}:'
                              '${at.minute.toString().padLeft(2, '0')}',
                  ),
                  if (!skipped && reading.planVersionId == null)
                    Text(
                      reading.outsideTarget == null
                          ? context.tr('measurements.without_target')
                          : reading.kind == MeasurementKind.glucose
                          ? '${context.tr('measurements.target')}: '
                                '${reading.glucoseLow}–${reading.glucoseHigh}'
                          : '${context.tr('measurements.target')}: '
                                '${reading.systolicLimit}/${reading.diastolicLimit}',
                    ),
                  // «بعد جهد، بعد القهوة».
                  if (!skipped && reading.conditions.isNotEmpty)
                    Text(readingConditionsText(context, reading)),
                  if (reading.note != null) Text(reading.note!),
                  if (reading.recordedByName case final name?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PersonPhoto(
                          name: name,
                          photoPath: personPhotoPath(
                            widget.circleId,
                            reading.recordedByAccountId,
                          ),
                          avatarCode: reading.recordedByAvatarCode,
                          size: AppSizes.iconSmall,
                        ),
                        const SizedBox(width: AppSpacing.tight),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              skipped ? context.tr('measurements.skipped') : reading.valueText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: reading.outsideTarget == true
                    ? AppSemanticColors.statusWarning
                    : AppSemanticColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
