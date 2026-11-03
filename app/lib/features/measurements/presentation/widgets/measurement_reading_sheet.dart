import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool> showMeasurementReadingSheet(
  BuildContext context, {
  MeasurementOccurrence? occurrence,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<MeasurementReadingsCubit>(),
        child: MeasurementReadingSheet(occurrence: occurrence),
      ),
    ) ??
    false;

class MeasurementReadingSheet extends StatefulWidget {
  const MeasurementReadingSheet({super.key, this.occurrence});

  final MeasurementOccurrence? occurrence;

  @override
  State<MeasurementReadingSheet> createState() =>
      _MeasurementReadingSheetState();
}

class _MeasurementReadingSheetState extends State<MeasurementReadingSheet> {
  late MeasurementKind _kind = widget.occurrence?.kind ?? MeasurementKind.bp;
  late bool _link = widget.occurrence != null;
  String _context = 'fasting';
  String? _condition;
  TimeOfDay _time = TimeOfDay.now();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _glucose = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _errorKey;

  static const _contexts = [
    'fasting',
    'before_meal',
    'after_meal',
    'bedtime',
    'other',
  ];
  static const _conditions = ['exertion', 'after_meal', 'stress', 'illness'];

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _glucose.dispose();
    _note.dispose();
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
    final now = DateTime.now();
    final measuredAt = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    if (measuredAt.isAfter(now)) {
      setState(() => _errorKey = 'measurements.future_reading');
      return;
    }
    final draft = MeasurementReadingDraft(
      kind: _kind,
      outcome: 'read',
      measuredAt: measuredAt,
      valueOne: one,
      valueTwo: two,
      glucoseContext: _kind == MeasurementKind.glucose ? _context : null,
      condition: _condition,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final cubit = context.read<MeasurementReadingsCubit>();
    final saved = await cubit.record(
      draft,
      occurrence: _link ? widget.occurrence : null,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _errorKey = cubit.state.errorKey ?? 'error.unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height * .9),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                context.tr('measurements.record_reading'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassSegmentedControl<MeasurementKind>(
                segments: {
                  MeasurementKind.bp: context.tr('measurements.bp'),
                  MeasurementKind.glucose: context.tr('measurements.glucose'),
                },
                selected: _kind,
                onChanged: widget.occurrence == null
                    ? (value) => setState(() => _kind = value)
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
              const SizedBox(height: AppSpacing.lg),
              if (_kind == MeasurementKind.glucose) ...[
                InsetGroup(
                  header: context.tr('measurements.glucose_context'),
                  children: [
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
                              onSelected: (_) =>
                                  setState(() => _context = value),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              InsetGroup(
                header: context.tr('measurements.condition_optional'),
                children: [
                  InsetBlock(
                    semanticLabel: context.tr(
                      'measurements.condition_optional',
                    ),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final value in _conditions)
                          ChoiceChip(
                            label: Text(
                              context.tr('measurements.condition.$value'),
                            ),
                            selected: _condition == value,
                            onSelected: (_) => setState(() {
                              _condition = _condition == value ? null : value;
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              InsetGroup(
                children: [
                  InsetRow(
                    label: context.tr('measurements.actual_time'),
                    value: _formatTime(_time),
                    onTap: () async {
                      final selected = await showTafaqodTimeSheet(
                        context,
                        title: context.tr('measurements.actual_time'),
                        initialTime: _time,
                      );
                      if (selected != null) setState(() => _time = selected);
                    },
                  ),
                ],
              ),
              if (widget.occurrence != null) ...[
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  value: _link,
                  onChanged: (value) => setState(() => _link = value ?? false),
                  title: Text(context.tr('measurements.link_task')),
                  subtitle: Text(context.tr('measurements.link_task_hint')),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppSemanticColors.actionPrimary,
                ),
              ],
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
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(context.tr('measurements.save_reading')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) => Column(
    children: [
      Text(context.tr(label)),
      const SizedBox(height: AppSpacing.xs),
      TextField(
        controller: controller,
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

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${context.tr(value.hour < 12 ? 'common.am' : 'common.pm')}';
  }
}
