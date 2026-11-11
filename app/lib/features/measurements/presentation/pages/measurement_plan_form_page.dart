import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
/// times, days, start and grace while the form switches between them, and
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
  int grace = 60;
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
  int get _grace => _schedule.grace;
  set _grace(int value) => _schedule.grace = value;

  final _low = TextEditingController();
  final _high = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _errorKey;

  static const _weekOrder = [6, 7, 1, 2, 3, 4, 5];

  /// Several planned readings can share the same day.
  static const int _maxReadings = 6;

  @override
  void dispose() {
    _low.dispose();
    _high.dispose();
    _systolic.dispose();
    _diastolic.dispose();
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
    _low.text = '${version.glucoseLow ?? ''}';
    _high.text = '${version.glucoseHigh ?? ''}';
    _systolic.text = '${version.systolicLimit ?? ''}';
    _diastolic.text = '${version.diastolicLimit ?? ''}';
    _grace = version.graceMinutes;
  }

  Future<void> _save(MeasurementPlan? plan) async {
    if (plan == null &&
        context.read<MeasurementPlansCubit>().state.plans.any(
          (item) => item.kind == _kind && item.stoppedAt == null,
        )) {
      setState(() => _errorKey = 'measurements.active_plan_exists');
      return;
    }
    final low = int.tryParse(_low.text);
    final high = int.tryParse(_high.text);
    final systolic = int.tryParse(_systolic.text);
    final diastolic = int.tryParse(_diastolic.text);
    if (_days.isEmpty) {
      setState(() => _errorKey = 'measurements.days_required');
      return;
    }
    final times = <String>{for (final item in _readings) _clock(item.time)};
    if (times.length != _readings.length) {
      setState(() => _errorKey = 'measurements.times_repeat');
      return;
    }
    if (_kind == MeasurementKind.glucose &&
        (low == null ||
            high == null ||
            low <= 0 ||
            high > 999 ||
            high <= low)) {
      setState(() => _errorKey = 'measurements.invalid_glucose_target');
      return;
    }
    if (_kind == MeasurementKind.bp &&
        (systolic == null ||
            diastolic == null ||
            systolic <= 0 ||
            systolic > 999 ||
            diastolic <= 0 ||
            diastolic > 999 ||
            systolic <= diastolic)) {
      setState(() => _errorKey = 'measurements.invalid_bp_target');
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
      graceMinutes: _grace,
      glucoseLow: _kind == MeasurementKind.glucose ? low : null,
      glucoseHigh: _kind == MeasurementKind.glucose ? high : null,
      systolicLimit: _kind == MeasurementKind.bp ? systolic : null,
      diastolicLimit: _kind == MeasurementKind.bp ? diastolic : null,
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
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr('measurements.active_plan_exists')),
            TextButton(
              onPressed: () {
                final router = GoRouter.of(context);
                final path = Routes.editMeasurement(
                  widget.circleId,
                  existing!.id,
                );
                context.pop();
                router.push(path);
              },
              child: Text(context.tr('measurements.edit_plan')),
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
                    Row(
                      children: [
                        for (final day in _weekOrder)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.xs,
                              ),
                              child: InkWell(
                                onTap: () => setState(() {
                                  if (!_days.remove(day)) _days.add(day);
                                }),
                                child: Container(
                                  alignment: Alignment.center,
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _days.contains(day)
                                        ? AppSemanticColors.selectedSurface
                                        : AppSemanticColors.surfaceContent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    context.tr(
                                      'medications.weekday_short.$day',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
              InsetRow(
                label: context.tr('measurements.grace'),
                value: context.tr('measurements.minutes', args: ['$_grace']),
                onTap: () => setState(() {
                  _grace = _grace == 30
                      ? 60
                      : _grace == 60
                      ? 120
                      : 30;
                }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('measurements.target'),
            children: _kind == MeasurementKind.glucose
                ? [
                    _numberRow(context, 'measurements.glucose_low', _low),
                    _numberRow(
                      context,
                      'measurements.glucose_high',
                      _high,
                      errorKey: 'measurements.invalid_glucose_target',
                    ),
                  ]
                : [
                    _numberRow(
                      context,
                      'measurements.systolic_limit',
                      _systolic,
                    ),
                    _numberRow(
                      context,
                      'measurements.diastolic_limit',
                      _diastolic,
                      errorKey: 'measurements.invalid_bp_target',
                    ),
                  ],
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
          if (_errorKey != null &&
              _errorKey != 'measurements.invalid_glucose_target' &&
              _errorKey != 'measurements.invalid_bp_target')
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

  Widget _numberRow(
    BuildContext context,
    String key,
    TextEditingController controller, {
    String? errorKey,
  }) => InsetTextRow(
    label: context.tr(key),
    controller: controller,
    errorText: errorKey != null && _errorKey == errorKey
        ? context.tr(errorKey)
        : null,
    onChanged: (_) => setState(() => _errorKey = null),
    keyboardType: TextInputType.number,
    inputFormatters: [
      const WesternDigitsFormatter(),
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
  );

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
