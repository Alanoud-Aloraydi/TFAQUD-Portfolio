import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Opens «تسجيل قراءة» over [context], whose [MeasurementReadingsCubit]
/// saves it: the answer to [occurrence], the task the person chose, or a
/// free reading when it is null. True when a reading was saved.
Future<bool> showMeasurementReadingSheet(
  BuildContext context, {
  MeasurementOccurrence? occurrence,
}) async =>
    await showGlassSheet<bool>(
      context,
      title: context.tr('measurements.record_reading'),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<MeasurementReadingsCubit>()),
          BlocProvider(
            create: (_) =>
                MeasurementRangesCubit(GetIt.I<MeasurementRepository>())
                  ..load(context.read<MeasurementReadingsCubit>().circleId!),
          ),
        ],
        child: MeasurementReadingSheet(occurrence: occurrence),
      ),
    ) ??
    false;

/// «تسجيل قراءة»: the values, conditions and time of one reading. A free
/// reading also picks its kind. «المعدل الطبيعي» under the values follows
/// the kind and the meal state chosen, and marks where the typed value
/// falls.
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
  bool _saving = false;
  String? _errorKey;

  /// The meal state chosen among the conditions, which picks the glucose
  /// range.
  String? get _mealState => _conditions
      .where(
        (code) => const <String>[
          'fasting',
          'before_meal',
          'after_meal',
          'bedtime',
        ].contains(code),
      )
      .firstOrNull;

  /// Where the typed value falls in [range]; null until it is a number.
  MeasurementLevel? _levelIn(NormalRange range) {
    final int? one = int.tryParse(
      _kind == MeasurementKind.bp ? _systolic.text : _glucose.text,
    );
    if (one == null || one < 1) return null;
    if (_kind == MeasurementKind.glucose) return range.levelOf(one);
    final int? two = int.tryParse(_diastolic.text);
    return two == null || two < 1 ? null : range.levelOf(one, two);
  }

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _glucose.dispose();
    _note.dispose();
    _otherCondition.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
    // The glass sheet draws the title, scrolls, and stays above the
    // keyboard.
    final NormalRange? range = context
        .watch<MeasurementRangesCubit>()
        .state
        .ranges
        ?.of(_kind, _mealState);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSegmentedControl<MeasurementKind>(
              segments: {
                MeasurementKind.bp: context.tr('measurements.bp'),
                MeasurementKind.glucose: context.tr('measurements.glucose'),
              },
              selected: _kind,
              onChanged: widget.occurrence == null
                  ? (value) => setState(() {
                      _kind = value;
                      // Fasting is not for blood pressure.
                      final offered = MeasurementConditions.offered(value);
                      _conditions = [
                        for (final code in _conditions)
                          if (offered.contains(code)) code,
                      ];
                    })
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    _kind == MeasurementKind.bp
                        ? 'measurements.systolic'
                        : 'measurements.value',
                    _kind == MeasurementKind.bp ? _systolic : _glucose,
                  ),
                ),
                if (_kind == MeasurementKind.bp) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      '/',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Expanded(
                    child: _numberField('measurements.diastolic', _diastolic),
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
            // Read-only and never in the way: saving does not wait for
            // it, the server judges the reading either way.
            if (range != null) ...[
              const SizedBox(height: AppSpacing.lg),
              NormalRangeCard(range: range, level: _levelIn(range)),
            ],
            const SizedBox(height: AppSpacing.lg),
            InsetGroup(
              header: context.tr('measurements.condition_optional'),
              children: [
                InsetBlock(
                  semanticLabel: context.tr('measurements.condition_optional'),
                  child: MeasurementConditionChips(
                    kind: _kind,
                    selected: _conditions,
                    caption: context.tr('measurements.conditions_hint'),
                    onChanged: (value) => setState(() => _conditions = value),
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
                helperText: context.tr('measurements.other_condition_hint'),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(context.tr('measurements.save_reading')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(String label, TextEditingController controller) => Column(
    children: [
      Text(context.tr(label)),
      const SizedBox(height: AppSpacing.xs),
      TextField(
        controller: controller,
        // The level under the values follows what is typed.
        onChanged: (_) => setState(() {}),
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
