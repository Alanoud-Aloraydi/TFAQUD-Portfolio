import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
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

class _MeasurementPlanFormPageState extends State<MeasurementPlanFormPage> {
  MeasurementKind _kind = MeasurementKind.glucose;
  String _context = 'fasting';
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 30);
  DateTime _start = DateUtils.dateOnly(
    DateTime.now().toUtc().add(const Duration(hours: 3)),
  );
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  final _low = TextEditingController();
  final _high = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  int _grace = 60;
  bool _initialized = false;
  bool _saving = false;
  String? _errorKey;

  static const _weekOrder = [6, 7, 1, 2, 3, 4, 5];
  static const _contexts = [
    'fasting',
    'before_meal',
    'after_meal',
    'bedtime',
    'other',
  ];

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
    final version = plan.version;
    _kind = plan.kind;
    _context = version.glucoseContext ?? 'fasting';
    final parts = version.time.split(':');
    _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final earliest = DateUtils.dateOnly(
      DateTime.now().toUtc().add(const Duration(hours: 3)),
    ).add(const Duration(days: 1));
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
    final low = int.tryParse(_low.text);
    final high = int.tryParse(_high.text);
    final systolic = int.tryParse(_systolic.text);
    final diastolic = int.tryParse(_diastolic.text);
    if (_days.isEmpty ||
        (_kind == MeasurementKind.glucose
            ? low == null ||
                  high == null ||
                  low <= 0 ||
                  high > 999 ||
                  high <= low
            : systolic == null ||
                  diastolic == null ||
                  systolic <= 0 ||
                  systolic > 999 ||
                  diastolic <= 0 ||
                  diastolic > 999 ||
                  systolic <= diastolic)) {
      setState(() => _errorKey = 'measurements.invalid_plan');
      return;
    }
    final draft = MeasurementPlanDraft(
      kind: _kind,
      time:
          '${_time.hour.toString().padLeft(2, '0')}:'
          '${_time.minute.toString().padLeft(2, '0')}',
      weekdays: _days.toList()..sort(),
      startsOn: _start,
      graceMinutes: _grace,
      glucoseContext: _kind == MeasurementKind.glucose ? _context : null,
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
    final saved = plan == null
        ? await cubit.create(draft)
        : await cubit.revise(plan, draft);
    if (!mounted) return;
    if (saved) {
      context.pop(true);
    } else {
      setState(() {
        _saving = false;
        _errorKey = cubit.state.errorKey ?? 'error.unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementPlansCubit>().state;
    MeasurementPlan? plan;
    if (widget.planId != null) {
      for (final item in state.plans) {
        if (item.id == widget.planId) plan = item;
      }
      if (plan != null) _fill(plan);
    }
    if (widget.planId != null && plan == null) {
      return Scaffold(
        body: Center(
          child: state.status == MeasurementLoadStatus.loading
              ? const CircularProgressIndicator()
              : Text(context.tr(state.errorKey ?? 'error.resource_not_found')),
        ),
      );
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
                    onPressed: _saving ? null : () => _save(plan),
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
          InsetGroup(
            header: context.tr('measurements.measurement'),
            children: [
              InsetBlock(
                semanticLabel: context.tr('measurements.kind'),
                child: GlassSegmentedControl<MeasurementKind>(
                  segments: {
                    MeasurementKind.glucose: context.tr('measurements.glucose'),
                    MeasurementKind.bp: context.tr('measurements.bp'),
                  },
                  selected: _kind,
                  onChanged: plan == null
                      ? (value) => setState(() => _kind = value)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('measurements.schedule'),
            children: [
              InsetRow(
                label: context.tr('measurements.time'),
                value: _formatTime(_time),
                onTap: () async {
                  final selected = await showTafaqodTimeSheet(
                    context,
                    title: context.tr('measurements.time'),
                    initialTime: _time,
                  );
                  if (selected != null) setState(() => _time = selected);
                },
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
                                        : AppSemanticColors.surfacePlan,
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
              if (_kind == MeasurementKind.glucose)
                InsetBlock(
                  semanticLabel: context.tr('measurements.glucose_context'),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final value in _contexts)
                        ChoiceChip(
                          label: Text(
                            context.tr('measurements.context.$value'),
                          ),
                          selected: _context == value,
                          onSelected: (_) => setState(() => _context = value),
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
                  final today = DateUtils.dateOnly(
                    DateTime.now().toUtc().add(const Duration(hours: 3)),
                  );
                  final earliest = plan == null
                      ? today
                      : today.add(const Duration(days: 1));
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
                  if (selected != null) setState(() => _start = selected);
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
                    _numberRow(context, 'measurements.glucose_high', _high),
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

  Widget _numberRow(
    BuildContext context,
    String key,
    TextEditingController controller,
  ) => InsetTextRow(
    label: context.tr(key),
    controller: controller,
    onChanged: (_) => setState(() => _errorKey = null),
    keyboardType: TextInputType.number,
    inputFormatters: [
      const WesternDigitsFormatter(),
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
  );

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${context.tr(value.hour < 12 ? 'common.am' : 'common.pm')}';
  }
}
