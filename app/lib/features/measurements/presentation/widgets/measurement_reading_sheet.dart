import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_targets_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Opens «تسجيل قراءة» over [context], whose [MeasurementReadingsCubit]
/// saves it: the answer to [occurrence], the task the person chose, or a
/// free reading when it is null. True when a reading was saved.
Future<bool> showMeasurementReadingSheet(
  BuildContext context, {
  MeasurementOccurrence? occurrence,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      // Above the top bar and the tab bar, below the status bar and the
      // Dynamic Island, with a gap above it to see it is a sheet; the grip
      // stays in reach to pull it down.
      useRootNavigator: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<MeasurementReadingsCubit>()),
          BlocProvider(
            create: (_) =>
                MeasurementTargetsCubit(GetIt.I<MeasurementRepository>())
                  ..load(context.read<MeasurementReadingsCubit>().circleId!),
          ),
        ],
        child: MeasurementReadingSheet(occurrence: occurrence),
      ),
    ) ??
    false;

/// «تسجيل قراءة»: the values, conditions and time of one reading. A free
/// reading also picks its kind and shows the patient's target (editable
/// when no plan sets it).
class MeasurementReadingSheet extends StatefulWidget {
  const MeasurementReadingSheet({super.key, this.occurrence});

  final MeasurementOccurrence? occurrence;

  @override
  State<MeasurementReadingSheet> createState() =>
      _MeasurementReadingSheetState();
}

class _MeasurementReadingSheetState extends State<MeasurementReadingSheet> {
  late MeasurementKind _kind = widget.occurrence?.kind ?? MeasurementKind.bp;

  /// The planned glucose state is only a starting point; these remain the
  /// actual conditions of the reading and can be changed by the recorder.
  late List<String> _conditions = widget.occurrence?.measurementState == null
      ? const <String>[]
      : <String>[widget.occurrence!.measurementState!];

  /// The time picked; until then, now on the patient's clock.
  TimeOfDay? _picked;
  TimeOfDay get _time =>
      _picked ?? TimeOfDay.fromDateTime(PatientClockScope.of(context).now());
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _glucose = TextEditingController();
  final _note = TextEditingController();

  /// What «أخرى» was, in the reader's words.
  final _otherCondition = TextEditingController();

  /// The longest words «أخرى» takes, as the server keeps them.
  static const int _otherConditionLength = 60;
  final _targetLow = TextEditingController();
  final _targetHigh = TextEditingController();
  bool _saving = false;
  String? _errorKey;

  MeasurementTarget? _targetFor(MeasurementKind kind) {
    for (final target
        in context.read<MeasurementTargetsCubit>().state.targets) {
      if (target.kind == kind) return target;
    }
    return null;
  }

  void _showTarget(MeasurementKind kind) {
    final target = _targetFor(kind);
    _targetLow.text =
        '${kind == MeasurementKind.bp ? target?.diastolicLimit ?? '' : target?.glucoseLow ?? ''}';
    _targetHigh.text =
        '${kind == MeasurementKind.bp ? target?.systolicLimit ?? '' : target?.glucoseHigh ?? ''}';
  }

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _glucose.dispose();
    _note.dispose();
    _otherCondition.dispose();
    _targetLow.dispose();
    _targetHigh.dispose();
    super.dispose();
  }

  /// Closes the sheet, saving nothing, and opens the plan whose target it
  /// shows.
  void _editPlan(String planId) {
    final GoRouter router = GoRouter.of(context);
    final String path = Routes.editMeasurement(
      context.read<MeasurementReadingsCubit>().circleId!,
      planId,
    );
    Navigator.of(context).pop(false);
    router.push(path);
  }

  Future<void> _save() async {
    final freeReading = widget.occurrence == null;
    final targetsState = context.read<MeasurementTargetsCubit>().state;
    if (freeReading &&
        (targetsState.loading || targetsState.errorKey != null)) {
      return;
    }
    final useTarget = freeReading && _targetFor(_kind)?.planId == null;
    final targetLow = useTarget ? int.tryParse(_targetLow.text) : null;
    final targetHigh = useTarget ? int.tryParse(_targetHigh.text) : null;
    if (useTarget &&
        (targetLow == null ||
            targetHigh == null ||
            targetLow < 1 ||
            targetHigh > 999 ||
            targetHigh <= targetLow)) {
      setState(() => _errorKey = 'measurements.invalid_free_target');
      return;
    }
    final one = int.tryParse(
      _kind == MeasurementKind.bp ? _systolic.text : _glucose.text,
    );
    final two = _kind == MeasurementKind.bp
        ? int.tryParse(_diastolic.text)
        : null;
    if (one == null ||
        one < 1 ||
        one > 999 ||
        (_kind == MeasurementKind.bp &&
            (two == null || two < 1 || two > 999 || one <= two))) {
      setState(() => _errorKey = 'measurements.invalid_reading');
      return;
    }
    // The time read is the patient's wall clock where they live, wherever
    // this phone is: the latest such time, so last night's after midnight.
    final PatientClock clock = PatientClockScope.of(context);
    final measuredAt = latestReadingMoment(
      clock,
      '${_time.hour}:${_time.minute}',
    );
    final draft = MeasurementReadingDraft(
      kind: _kind,
      outcome: 'read',
      measuredAt: measuredAt,
      valueOne: one,
      valueTwo: two,
      conditions: _conditions,
      otherCondition:
          _conditions.contains('other') &&
              _otherCondition.text.trim().isNotEmpty
          ? _otherCondition.text.trim()
          : null,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      glucoseLow: useTarget && _kind == MeasurementKind.glucose
          ? targetLow
          : null,
      glucoseHigh: useTarget && _kind == MeasurementKind.glucose
          ? targetHigh
          : null,
      systolicLimit: useTarget && _kind == MeasurementKind.bp
          ? targetHigh
          : null,
      diastolicLimit: useTarget && _kind == MeasurementKind.bp
          ? targetLow
          : null,
    );
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final String? errorKey = await context
        .read<MeasurementReadingsCubit>()
        .record(draft, clock: clock, occurrence: widget.occurrence);
    if (!mounted) return;
    if (errorKey == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _errorKey = errorKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocListener<MeasurementTargetsCubit, MeasurementTargetsState>(
      listener: (context, state) {
        if (!state.loading && state.errorKey == null) _showTarget(_kind);
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * .84),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    context.tr('measurements.record_reading'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      GlassSegmentedControl<MeasurementKind>(
                        segments: {
                          MeasurementKind.bp: context.tr('measurements.bp'),
                          MeasurementKind.glucose: context.tr(
                            'measurements.glucose',
                          ),
                        },
                        selected: _kind,
                        onChanged: widget.occurrence == null
                            ? (value) => setState(() {
                                _kind = value;
                                _showTarget(value);
                                // Fasting is not for blood pressure.
                                final offered = MeasurementConditions.offered(
                                  value,
                                );
                                _conditions = [
                                  for (final code in _conditions)
                                    if (offered.contains(code)) code,
                                ];
                              })
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (widget.occurrence == null) ...[
                        if (context
                            .watch<MeasurementTargetsCubit>()
                            .state
                            .loading)
                          const Center(child: CircularProgressIndicator())
                        else if (context
                                .watch<MeasurementTargetsCubit>()
                                .state
                                .errorKey
                            case final error?)
                          TextButton(
                            onPressed: () =>
                                context.read<MeasurementTargetsCubit>().load(
                                  context
                                      .read<MeasurementReadingsCubit>()
                                      .circleId!,
                                ),
                            // Tapping the message reads the targets again,
                            // as the other measurement lists retry.
                            child: Text(context.tr(error)),
                          )
                        else ...[
                          InsetGroup(
                            header: context.tr('measurements.target'),
                            footer: context.tr(
                              _targetFor(_kind)?.planId == null
                                  ? 'measurements.free_target_hint'
                                  : 'measurements.plan_target_hint',
                            ),
                            children: [
                              InsetBlock(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _numberField(
                                        _kind == MeasurementKind.bp
                                            ? 'measurements.systolic_limit'
                                            : 'measurements.glucose_low',
                                        _kind == MeasurementKind.bp
                                            ? _targetHigh
                                            : _targetLow,
                                        enabled:
                                            _targetFor(_kind)?.planId == null,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _numberField(
                                        _kind == MeasurementKind.bp
                                            ? 'measurements.diastolic_limit'
                                            : 'measurements.glucose_high',
                                        _kind == MeasurementKind.bp
                                            ? _targetLow
                                            : _targetHigh,
                                        enabled:
                                            _targetFor(_kind)?.planId == null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // A target from a plan is changed in the plan:
                              // an action row, as «إضافة قراءة» is.
                              if (_targetFor(_kind)?.planId case final planId?)
                                InsetRow(
                                  label: context.tr(
                                    'measurements.edit_plan_target',
                                  ),
                                  leading: const Icon(AppIcons.pencil),
                                  showChevron: true,
                                  onTap: () => _editPlan(planId),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              _kind == MeasurementKind.bp
                                  ? 'measurements.systolic'
                                  : 'measurements.value',
                              _kind == MeasurementKind.bp
                                  ? _systolic
                                  : _glucose,
                            ),
                          ),
                          if (_kind == MeasurementKind.bp) ...[
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                '/',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                            Expanded(
                              child: _numberField(
                                'measurements.diastolic',
                                _diastolic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        context.tr(
                          _kind == MeasurementKind.bp
                              ? 'measurements.bp_unit'
                              : 'measurements.glucose_unit',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      InsetGroup(
                        header: context.tr('measurements.condition_optional'),
                        children: [
                          InsetBlock(
                            semanticLabel: context.tr(
                              'measurements.condition_optional',
                            ),
                            child: MeasurementConditionChips(
                              kind: _kind,
                              selected: _conditions,
                              caption: context.tr(
                                'measurements.conditions_hint',
                              ),
                              onChanged: (value) =>
                                  setState(() => _conditions = value),
                            ),
                          ),
                        ],
                      ),
                      // «أخرى» in the reader's own words, as the medical
                      // file's «أخرى» takes them.
                      if (_conditions.contains('other')) ...[
                        const SizedBox(height: AppSpacing.md),
                        LabeledTextField(
                          label: context.tr('measurements.other_condition'),
                          helperText: context.tr(
                            'measurements.other_condition_hint',
                          ),
                          controller: _otherCondition,
                          maxLength: _otherConditionLength,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {},
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      InsetGroup(
                        children: [
                          InsetRow(
                            label: context.tr('measurements.actual_time'),
                            value: timeOfDayText(_time),
                            onTap: () async {
                              final selected = await showTafaqodTimeSheet(
                                context,
                                title: context.tr('measurements.actual_time'),
                                initialTime: _time,
                              );
                              if (selected != null && mounted) {
                                setState(() => _picked = selected);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      InsetGroup(
                        children: [
                          InsetTextRow(
                            label: context.tr('measurements.note'),
                            controller: _note,
                            onChanged: (_) {},
                            maxLength: 250,
                          ),
                        ],
                      ),
                      if (_errorKey != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            context.tr(_errorKey!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _saving ||
                              widget.occurrence == null &&
                                  (context
                                          .watch<MeasurementTargetsCubit>()
                                          .state
                                          .loading ||
                                      context
                                              .watch<MeasurementTargetsCubit>()
                                              .state
                                              .errorKey !=
                                          null)
                          ? null
                          : _save,
                      child: Text(context.tr('measurements.save_reading')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) => Column(
    children: [
      Text(context.tr(label)),
      const SizedBox(height: AppSpacing.xs),
      TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
        inputFormatters: [
          const WesternDigitsFormatter(),
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: AppSemanticColors.surfaceContent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    ],
  );
}
