import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/plan_limits.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/missed_after_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_ranges_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// «جدولة قياس» (new, [planId] null) or «تعديل جدولة القياس» of [planId].
///
/// An edit starts from the plan's latest version (a change waiting for
/// later, when there is one) and is saved against that version's number,
/// so a change made elsewhere meanwhile is refused, not overwritten.
class MeasurementPlanFormPage extends StatefulWidget {
  const MeasurementPlanFormPage({
    super.key,
    required this.circleId,
    this.planId,
  });

  final String circleId;
  final String? planId;

  @override
  State<MeasurementPlanFormPage> createState() =>
      _MeasurementPlanFormPageState();
}

/// One reading time and its glucose «حالة القياس».
class _Reading {
  _Reading(this.time, this.measurementState);

  TimeOfDay time;
  String? measurementState;
}

/// The schedule of one kind: glucose and blood pressure each keep their own
/// times, days, start and missed-after wait while the form switches between them, and
/// only the kind shown is saved.
class _Schedule {
  _Schedule(this.readings, this.start);

  /// The reading times of a day, like a medicine's dose times: one or more,
  /// up to [_MeasurementPlanFormPageState._maxReadings], each with its own
  /// glucose measurement state.
  final List<_Reading> readings;
  final Set<int> days = {1, 2, 3, 4, 5, 6, 7};

  /// The first day, on the patient's calendar.
  DateTime start;
  int? missedAfter = PlanLimits.defaultMissedAfterMinutes;
}

class _MeasurementPlanFormPageState extends State<MeasurementPlanFormPage> {
  MeasurementKind _kind = MeasurementKind.glucose;

  /// Made on first use, where the patient's today can be read: a new plan
  /// starts on it.
  late final Map<MeasurementKind, _Schedule> _schedules = {
    MeasurementKind.glucose: _Schedule(<_Reading>[
      _Reading(const TimeOfDay(hour: 7, minute: 30), 'fasting'),
    ], PatientClockScope.of(context).today()),
    MeasurementKind.bp: _Schedule(<_Reading>[
      _Reading(const TimeOfDay(hour: 8, minute: 0), null),
    ], PatientClockScope.of(context).today()),
  };

  _Schedule get _schedule => _schedules[_kind]!;
  List<_Reading> get _readings => _schedule.readings;
  Set<int> get _days => _schedule.days;
  DateTime get _start => _schedule.start;
  set _start(DateTime value) => _schedule.start = value;
  int? get _missedAfter => _schedule.missedAfter;
  set _missedAfter(int? value) => _schedule.missedAfter = value;

  /// «المعدل الطبيعي» of the patient: fixed, chosen by the medical file.
  late final MeasurementRangesCubit _ranges;
  bool _initialized = false;
  bool _saving = false;
  String? _errorKey;
  bool _missedAfterChecked = false;

  /// Several planned readings can share the same day.
  static const int _maxReadings = 6;

  @override
  void initState() {
    super.initState();
    _ranges = MeasurementRangesCubit(GetIt.I<MeasurementRepository>())
      ..load(widget.circleId);
  }

  @override
  void dispose() {
    _ranges.close();
    super.dispose();
  }

  void _fill(MeasurementPlan plan) {
    if (_initialized) return;
    _initialized = true;
    // The latest version: a change waiting for later, when there is one,
    // so editing again starts from it.
    final version = plan.pendingVersion ?? plan.version;
    _kind = plan.kind;
    _readings
      ..clear()
      ..addAll(<_Reading>[
        for (final MeasurementTime item in version.readingTimes)
          _Reading(_parseTime(item.time), item.measurementState),
      ]);
    final earliest = PatientClockScope.of(context).today();
    _start = version.effectiveFromOn.isAfter(earliest)
        ? version.effectiveFromOn
        : earliest;
    _days
      ..clear()
      ..addAll(version.weekdays);
    _missedAfter = version.missedAfterMinutes;
  }

  Future<void> _save(MeasurementPlan? plan) async {
    if (plan == null &&
        context.read<MeasurementPlansCubit>().state.plans.any(
          (item) => item.kind == _kind && item.stoppedAt == null,
        )) {
      setState(() => _errorKey = 'measurements.active_plan_exists');
      return;
    }
    if (_days.isEmpty) {
      setState(() => _errorKey = 'measurements.days_required');
      return;
    }
    if (!PlanLimits.isValidMissedAfter(_missedAfter)) {
      setState(() => _missedAfterChecked = true);
      return;
    }
    final times = <String>{for (final item in _readings) _clock(item.time)};
    if (times.length != _readings.length) {
      setState(() => _errorKey = 'measurements.times_repeat');
      return;
    }
    final readings = _readings.toList()
      ..sort((a, b) => _clock(a.time).compareTo(_clock(b.time)));
    final draft = MeasurementPlanDraft(
      kind: _kind,
      times: <MeasurementTime>[
        for (final item in readings)
          MeasurementTime(
            time: _clock(item.time),
            measurementState: item.measurementState,
          ),
      ],
      weekdays: _days.toList()..sort(),
      startsOn: _start,
      missedAfterMinutes: _missedAfter!,
    );
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final cubit = context.read<MeasurementPlansCubit>();
    final String? errorKey = plan == null
        ? await cubit.create(draft)
        : await cubit.revise(plan, draft);
    if (!mounted) return;
    if (errorKey == null) {
      AppToast.show(context, 'toast.measurement_plan_saved');
      context.pop(true);
    } else {
      setState(() {
        _saving = false;
        _errorKey = errorKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementPlansCubit>().state;
    MeasurementPlan? plan;
    if (widget.planId != null) {
      for (final item in state.plans) {
        // A stopped plan is not edited: it is gone from the plan tab.
        if (item.id == widget.planId && item.stoppedAt == null) plan = item;
      }
      if (plan != null) _fill(plan);
    }
    if (widget.planId != null && plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: switch (state.status) {
            MeasurementLoadStatus.initial ||
            MeasurementLoadStatus.loading => const CircularProgressIndicator(),
            MeasurementLoadStatus.failure => TextButton(
              onPressed: () =>
                  context.read<MeasurementPlansCubit>().load(widget.circleId),
              child: Text(context.tr(state.errorKey ?? 'error.unknown')),
            ),
            MeasurementLoadStatus.ready => Text(
              context.tr('error.resource_not_found'),
            ),
          },
        ),
      );
    }
    MeasurementPlan? existing;
    if (plan == null) {
      for (final item in state.plans) {
        if (item.kind == _kind && item.stoppedAt == null) {
          existing = item;
          break;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        title: GlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.capsule),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(context.tr('common.cancel')),
                ),
                Expanded(
                  child: Text(
                    context.tr(
                      plan == null
                          ? 'measurements.new_plan'
                          : 'measurements.edit_plan',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: FilledButton(
                    onPressed: _saving || existing != null
                        ? null
                        : () => _save(plan),
                    child: Text(context.tr('measurements.save')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
            child: Text(
              context.tr('measurements.measurement'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassSegmentedControl<MeasurementKind>(
            segments: {
              MeasurementKind.glucose: context.tr('measurements.glucose'),
              MeasurementKind.bp: context.tr('measurements.bp'),
            },
            selected: _kind,
            onChanged: plan == null
                ? (value) => setState(() {
                    _kind = value;
                    _errorKey = null;
                  })
                : null,
          ),
          if (existing != null) ...[
            const SizedBox(height: AppSpacing.md),
            // An action row: a pencil, the words, and a chevron.
            InsetGroup(
              footer: context.tr('measurements.active_plan_exists'),
              children: [
                InsetRow(
                  label: context.tr('measurements.edit_plan'),
                  leading: const Icon(AppIcons.pencil),
                  showChevron: true,
                  onTap: () {
                    final router = GoRouter.of(context);
                    final path = Routes.editMeasurement(
                      widget.circleId,
                      existing!.id,
                    );
                    context.pop();
                    router.push(path);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('measurements.schedule'),
            children: [
              for (int index = 0; index < _readings.length; index++)
                ..._readingRows(context, index),
              if (_readings.length < _maxReadings)
                InsetRow(
                  label: context.tr('measurements.add_reading'),
                  leading: const Icon(AppIcons.plusCircle),
                  onTap: _addReading,
                ),
              InsetBlock(
                semanticLabel: context.tr('measurements.days'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr('measurements.days')),
                    const SizedBox(height: AppSpacing.sm),
                    WeekdaySelector(
                      selected: _days,
                      onChanged: (Set<int> days) => setState(() {
                        _days
                          ..clear()
                          ..addAll(days);
                      }),
                    ),
                  ],
                ),
              ),
              InsetRow(
                label: context.tr(
                  plan == null
                      ? 'measurements.starts'
                      : 'measurements.effective_start',
                ),
                value: '${_start.day}/${_start.month}/${_start.year}',
                onTap: () async {
                  final earliest = PatientClockScope.of(context).today();
                  final selected = await showTafaqodDateSheet(
                    context,
                    title: context.tr(
                      plan == null
                          ? 'measurements.starts'
                          : 'measurements.effective_start',
                    ),
                    initialDate: _start.isBefore(earliest) ? earliest : _start,
                    firstDate: earliest,
                    lastDate: earliest.add(const Duration(days: 3650)),
                  );
                  if (selected != null && mounted) {
                    setState(() => _start = selected);
                  }
                },
              ),
              MissedAfterField(
                key: ValueKey<String>('missed-after-${_kind.name}'),
                label: context.tr('measurements.missed_after'),
                minutes: _missedAfter,
                showError: _missedAfterChecked,
                onChanged: (int? minutes) =>
                    setState(() => _missedAfter = minutes),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Fixed by the meal states above and the medical file: shown,
          // not typed.
          BlocProvider<MeasurementRangesCubit>.value(
            value: _ranges,
            child: MeasurementRangesBox(
              circleId: widget.circleId,
              kind: _kind,
              states: <String?>[
                for (final _Reading item in _readings) item.measurementState,
              ],
            ),
          ),
          if (plan != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                context.tr(
                  'measurements.edit_effective_hint',
                  args: ['${_start.day}/${_start.month}/${_start.year}'],
                ),
              ),
            ),
          if (_errorKey != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                context.tr(_errorKey!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  /// One reading: its time («القراءة 2» when there are several), its
  /// glucose context, and «حذف» for all but a single reading.
  List<Widget> _readingRows(BuildContext context, int index) {
    final _Reading reading = _readings[index];
    final String label = _readings.length == 1
        ? context.tr('measurements.time')
        : context.tr('measurements.reading_number', args: ['${index + 1}']);
    return <Widget>[
      InsetRow(
        label: label,
        value: timeOfDayText(reading.time),
        trailing: _readings.length == 1
            ? null
            : IconButton(
                tooltip: context.tr(
                  'measurements.remove_reading',
                  args: ['${index + 1}'],
                ),
                icon: const Icon(AppIcons.trash),
                onPressed: () => setState(() {
                  _readings.removeAt(index);
                  _errorKey = null;
                }),
              ),
        onTap: () async {
          final selected = await showTafaqodTimeSheet(
            context,
            title: label,
            initialTime: reading.time,
          );
          if (selected != null && mounted) {
            setState(() {
              reading.time = selected;
              _errorKey = null;
            });
          }
        },
      ),
      if (_kind == MeasurementKind.glucose)
        InsetBlock(
          semanticLabel: '$label، ${context.tr('measurements.state')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('measurements.state'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              OptionChips(
                options: [
                  for (final value in const [
                    'fasting',
                    'before_meal',
                    'after_meal',
                  ])
                    ChipOption(
                      value,
                      context.tr('measurements.condition.$value'),
                    ),
                ],
                isSelected: (value) => reading.measurementState == value,
                onTap: (value) => setState(() {
                  reading.measurementState = value;
                  _errorKey = null;
                }),
              ),
            ],
          ),
        ),
    ];
  }

  /// A new reading three hours after the last one (the same day); a
  /// glucose one with the next meal state not used yet: fasting, then
  /// before a meal, then after it.
  void _addReading() {
    final TimeOfDay last = _readings.last.time;
    final int next = last.hour * 60 + last.minute + 180;
    final int minutes = next > 23 * 60 ? 23 * 60 : next;
    final Set<String> used = {
      for (final item in _readings) ?item.measurementState,
    };
    const mealStates = <String>['fasting', 'before_meal', 'after_meal'];
    final String? meal = _kind == MeasurementKind.glucose
        ? mealStates.where((value) => !used.contains(value)).firstOrNull
        : null;
    setState(() {
      _readings.add(
        _Reading(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60), meal),
      );
      _errorKey = null;
    });
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _clock(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
