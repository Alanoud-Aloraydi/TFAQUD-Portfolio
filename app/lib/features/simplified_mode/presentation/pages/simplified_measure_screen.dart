import 'dart:async';

import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_field.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_keypad.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_value_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_segmented.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «تسجيل قياس»: blood pressure or glucose, a big number typed on a big
/// keypad, the optional circumstances, and one save button.
class SimplifiedMeasureScreen extends StatefulWidget {
  const SimplifiedMeasureScreen({super.key});

  @override
  State<SimplifiedMeasureScreen> createState() =>
      _SimplifiedMeasureScreenState();
}

class _SimplifiedMeasureScreenState extends State<SimplifiedMeasureScreen> {
  MeasurementKind? _kind;
  final Map<SimplifiedMeasureField, String> _values =
      <SimplifiedMeasureField, String>{
        for (final SimplifiedMeasureField field
            in SimplifiedMeasureField.values)
          field: '',
      };
  SimplifiedMeasureField _upperOrLower = SimplifiedMeasureField.upper;

  /// «ظروف القياس» chosen; a task's start as its plan gives them, the same
  /// as the detailed mode's reading sheet.
  List<String> _conditions = const <String>[];
  final TextEditingController _note = TextEditingController();
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    // The kinds are known before anything loads (the task's own, else
    // both), so the form starts now. Waiting for «ready» missed it: the
    // cubit is made, and ready, by this very read, before any listener,
    // which left a free reading with no kind and «ما تقدر تسجّل».
    final SimplifiedMeasurementState state = context
        .read<SimplifiedMeasurementCubit>()
        .state;
    _show(state, state.kinds.firstOrNull);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  SimplifiedMeasureField get _active => _kind == MeasurementKind.glucose
      ? SimplifiedMeasureField.glucose
      : _upperOrLower;

  void _type(String digit) => setState(() {
    final String current = _values[_active]!;
    if (current.length < 3) _values[_active] = current + digit;
    _errorKey = null;
  });

  void _erase() => setState(() {
    final String current = _values[_active]!;
    if (current.isNotEmpty) {
      _values[_active] = current.substring(0, current.length - 1);
    }
    _errorKey = null;
  });

  SimplifiedReading? _reading() {
    final MeasurementKind? kind = _kind;
    if (kind == null) return null;
    final bool glucose = kind == MeasurementKind.glucose;
    final int? one = int.tryParse(
      _values[glucose
          ? SimplifiedMeasureField.glucose
          : SimplifiedMeasureField.upper]!,
    );
    final int? two = glucose
        ? null
        : int.tryParse(_values[SimplifiedMeasureField.lower]!);
    if (one == null || (!glucose && two == null)) return null;
    final String note = _note.text.trim();
    return SimplifiedReading(
      kind: kind,
      valueOne: one,
      valueTwo: two,
      conditions: _conditions,
      note: _conditions.contains('other') && note.isNotEmpty ? note : null,
    );
  }

  /// Shows [kind], starting its conditions from the task when there is one.
  void _show(SimplifiedMeasurementState state, MeasurementKind? kind) {
    _kind = kind;
    _conditions = state.task?.measurementState == null
        ? const <String>[]
        : <String>[state.task!.measurementState!];
    _errorKey = null;
  }

  Future<void> _save() async {
    final SimplifiedReading? reading = _reading();
    if (reading == null || !reading.isValid) {
      setState(() {
        _errorKey = reading?.kind == MeasurementKind.bp
            ? 'simplified_mode.invalid_bp'
            : 'measurements.invalid_reading';
      });
      return;
    }
    final bool saved = await context.read<SimplifiedMeasurementCubit>().save(
      reading,
    );
    if (!saved || !mounted) return;
    final MeasurementLevel? level = context
        .read<SimplifiedMeasurementCubit>()
        .state
        .saved
        ?.level;
    unawaited(context.read<SimplifiedModeCubit>().load());
    context.pushReplacement(
      Routes.simplifiedDone,
      extra: reading.kind == MeasurementKind.glucose
          ? SimplifiedDoneMessage.glucose(reading.valueOne, level: level)
          : SimplifiedDoneMessage.bloodPressure(
              reading.valueOne,
              reading.valueTwo!,
              level: level,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimplifiedMeasurementCubit, SimplifiedMeasurementState>(
      listenWhen: (before, after) => after.messageKey != before.messageKey,
      listener: (context, state) =>
          setState(() => _errorKey = state.messageKey),
      builder: (context, state) {
        // Never null: initState picks the first kind there is.
        final MeasurementKind kind = _kind ?? state.kinds.first;
        final bool ready = state.status == SimplifiedMeasurementStatus.ready;
        return SimplifiedPage(
          title: context.tr('simplified_mode.measure_title'),
          backKey: 'simplified_mode.close',
          // A failure is read too, not only the form.
          footer: ready
              ? SimplifiedButton(
                  label: context.tr('simplified_mode.save_reading'),
                  onPressed: state.saving || _reading() == null
                      ? null
                      : () => unawaited(_save()),
                )
              : null,
          children: switch (state.status) {
            SimplifiedMeasurementStatus.loading => const <Widget>[
              Center(child: CircularProgressIndicator()),
            ],
            SimplifiedMeasurementStatus.failure => <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                style: SimplifiedStyle.text(
                  SimplifiedStyle.body,
                  color: SimplifiedStyle.ink,
                ),
              ),
              SimplifiedButton(
                label: context.tr('simplified_mode.try_again'),
                onPressed: context.read<SimplifiedMeasurementCubit>().load,
              ),
            ],
            SimplifiedMeasurementStatus.ready => <Widget>[
              ..._form(context, state, kind),
              const SizedBox(height: SimplifiedStyle.gap),
              SimplifiedRecentReadings(
                readings: state.recent,
                kind: kind,
                now: PatientClockScope.of(context).now(),
              ),
            ],
          },
        );
      },
    );
  }

  /// What the detailed mode offers for [kind], and any the task already
  /// has that it no longer offers («قبل النوم»).
  List<String> _conditionCodes(MeasurementKind kind) {
    final List<String> offered = MeasurementConditions.offered(kind);
    return <String>[
      ...offered,
      for (final String code in _conditions)
        if (!offered.contains(code)) code,
    ];
  }

  String _hintKey(MeasurementKind kind) => kind == MeasurementKind.glucose
      ? 'simplified_mode.type_glucose'
      : _upperOrLower == SimplifiedMeasureField.upper
      ? 'simplified_mode.type_upper'
      : 'simplified_mode.type_lower';

  List<Widget> _form(
    BuildContext context,
    SimplifiedMeasurementState state,
    MeasurementKind kind,
  ) {
    final bool glucose = kind == MeasurementKind.glucose;
    final List<String> codes = _conditionCodes(kind);
    return <Widget>[
      if (state.kinds.length > 1)
        SimplifiedSegmented<MeasurementKind>(
          segments: <MeasurementKind, String>{
            for (final MeasurementKind item in state.kinds)
              item: context.tr('measurements.${item.name}'),
          },
          selected: kind,
          onChanged: (value) => setState(() => _show(state, value)),
        ),
      if (glucose)
        SimplifiedMeasureValueCard(
          value: _values[SimplifiedMeasureField.glucose]!,
          unit: context.tr('measurements.glucose_unit'),
          active: true,
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (SimplifiedMeasureField field, String label)
                in <(SimplifiedMeasureField, String)>[
                  (
                    SimplifiedMeasureField.upper,
                    context.tr('simplified_mode.upper'),
                  ),
                  (
                    SimplifiedMeasureField.lower,
                    context.tr('simplified_mode.lower'),
                  ),
                ]) ...<Widget>[
              if (field == SimplifiedMeasureField.lower)
                const SizedBox(height: 8),
              Semantics(
                button: true,
                selected: _upperOrLower == field,
                label: spoken(label),
                child: GestureDetector(
                  onTap: () => setState(() => _upperOrLower = field),
                  child: SimplifiedMeasureValueCard(
                    value: _values[field]!,
                    unit: label,
                    active: _upperOrLower == field,
                    small: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      Text(
        context.tr(_errorKey ?? _hintKey(kind)),
        textAlign: TextAlign.center,
        style: SimplifiedStyle.text(
          SimplifiedStyle.body,
          color: _errorKey == null
              ? SimplifiedStyle.muted
              : SimplifiedStyle.danger,
          weight: AppTextTheme.medium,
        ),
      ),
      SimplifiedMeasureKeypad(onDigit: _type, onErase: _erase),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '${context.tr('simplified_mode.conditions')} ',
                  style: SimplifiedStyle.head(SimplifiedStyle.body),
                ),
                TextSpan(
                  text: context.tr('simplified_mode.optional'),
                  style: SimplifiedStyle.text(SimplifiedStyle.caption),
                ),
              ],
            ),
          ),
          Text(
            context.tr('simplified_mode.choose_many'),
            style: SimplifiedStyle.text(SimplifiedStyle.caption),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String code in codes)
                SimplifiedChip(
                  context.tr('measurements.condition.$code'),
                  selected: _conditions.contains(code),
                  // A meal state replaces the one already chosen (fasting
                  // and after a meal cannot both be true): the detailed
                  // mode's rule.
                  onTap: () => setState(
                    () => _conditions = MeasurementConditions.toggle(
                      _conditions,
                      code,
                    ),
                  ),
                ),
            ],
          ),
          if (_conditions.contains('other')) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 250,
              inputFormatters: const [CodePointLengthFormatter(250)],
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                color: SimplifiedStyle.ink,
                weight: AppTextTheme.medium,
              ),
              decoration: InputDecoration(
                hintText: context.tr('simplified_mode.other_hint'),
                filled: true,
                fillColor: SimplifiedStyle.surface,
                contentPadding: const EdgeInsets.all(18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: SimplifiedStyle.ink,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: SimplifiedStyle.ink,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ];
  }
}
