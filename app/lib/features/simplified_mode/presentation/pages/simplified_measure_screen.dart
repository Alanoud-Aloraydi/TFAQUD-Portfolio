import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_done_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which number the keypad types into.
enum _Field { glucose, upper, lower }

/// «تسجيل قياس»: blood pressure or glucose, a big number typed on a big
/// keypad, the optional circumstances, and one save button.
class SimplifiedMeasureScreen extends StatefulWidget {
  const SimplifiedMeasureScreen({super.key, this.lockedKind});

  /// The kind of the task this reading answers; null lets the patient
  /// choose among the kinds that can be recorded.
  final MeasurementKind? lockedKind;

  @override
  State<SimplifiedMeasureScreen> createState() =>
      _SimplifiedMeasureScreenState();
}

class _SimplifiedMeasureScreenState extends State<SimplifiedMeasureScreen> {
  MeasurementKind? _kind;

  /// Whether the first load chose the kind and its starting conditions.
  bool _started = false;
  final Map<_Field, String> _values = <_Field, String>{
    for (final _Field field in _Field.values) field: '',
  };
  _Field _upperOrLower = _Field.upper;

  /// «ظروف القياس» chosen; a task's start as its plan gives them, the same
  /// as the detailed mode's reading sheet.
  List<String> _conditions = const <String>[];
  final TextEditingController _note = TextEditingController();
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _kind = widget.lockedKind;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  _Field get _active =>
      _kind == MeasurementKind.glucose ? _Field.glucose : _upperOrLower;

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
      _values[glucose ? _Field.glucose : _Field.upper]!,
    );
    final int? two = glucose ? null : int.tryParse(_values[_Field.lower]!);
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

  /// Shows [kind], starting its conditions from today's task of it.
  void _show(SimplifiedMeasurementState state, MeasurementKind? kind) {
    _kind = kind;
    _conditions = kind == null
        ? const <String>[]
        : state.taskFor(kind, DateTime.now())?.conditions ?? const <String>[];
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
    unawaited(context.read<SimplifiedModeCubit>().load());
    context.pushReplacement(
      Routes.simplifiedDone,
      extra: reading.kind == MeasurementKind.glucose
          ? SimplifiedDoneMessage.glucose(reading.valueOne)
          : SimplifiedDoneMessage.bloodPressure(
              reading.valueOne,
              reading.valueTwo!,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimplifiedMeasurementCubit, SimplifiedMeasurementState>(
      listenWhen: (before, after) =>
          (after.status == SimplifiedMeasurementStatus.ready &&
              before.status != SimplifiedMeasurementStatus.ready) ||
          (after.messageKey != null &&
              after.messageKey != before.messageKey &&
              after.status == SimplifiedMeasurementStatus.ready),
      listener: (context, state) => setState(() {
        if (!_started) {
          // Loaded: the task's kind, else the first kind that can be read.
          _started = true;
          _show(state, _kind ?? state.kinds.firstOrNull);
        } else {
          _errorKey = state.messageKey;
        }
      }),
      builder: (context, state) {
        final MeasurementKind? kind = _kind;
        final bool ready =
            state.status == SimplifiedMeasurementStatus.ready && kind != null;
        return SimplifiedPage(
          title: context.tr('simplified_mode.measure_title'),
          backKey: 'simplified_mode.close',
          listen: ready ? _listen(context, kind) : const <String>[],
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
            SimplifiedMeasurementStatus.ready when kind == null => <Widget>[
              Text(
                context.tr('simplified_mode.no_target'),
                style: SimplifiedStyle.text(
                  SimplifiedStyle.body,
                  color: SimplifiedStyle.ink,
                ),
              ),
            ],
            SimplifiedMeasurementStatus.ready => _form(context, state, kind!),
          },
        );
      },
    );
  }

  List<String> _listen(BuildContext context, MeasurementKind kind) => <String>[
    context.tr('simplified_mode.measure_${kind.name}'),
    context.tr(_hintKey(kind)),
    context.tr('simplified_mode.save_reading'),
  ];

  String _hintKey(MeasurementKind kind) => kind == MeasurementKind.glucose
      ? 'simplified_mode.type_glucose'
      : _upperOrLower == _Field.upper
      ? 'simplified_mode.type_upper'
      : 'simplified_mode.type_lower';

  List<Widget> _form(
    BuildContext context,
    SimplifiedMeasurementState state,
    MeasurementKind kind,
  ) {
    final bool glucose = kind == MeasurementKind.glucose;
    // What the detailed mode offers for this kind, and any the task already
    // has that it no longer offers («قبل النوم»).
    final List<String> offered = MeasurementConditions.offered(kind);
    final List<String> codes = <String>[
      ...offered,
      for (final String code in _conditions)
        if (!offered.contains(code)) code,
    ];
    return <Widget>[
      if (widget.lockedKind == null && state.kinds.length > 1)
        SimplifiedSegmented<MeasurementKind>(
          segments: <MeasurementKind, String>{
            for (final MeasurementKind item in state.kinds)
              item: context.tr('measurements.${item.name}'),
          },
          selected: kind,
          onChanged: (value) => setState(() => _show(state, value)),
        ),
      if (glucose)
        _ValueCard(
          value: _values[_Field.glucose]!,
          unit: context.tr('measurements.glucose_unit'),
          active: true,
        )
      else
        Row(
          children: <Widget>[
            for (final (_Field field, String label) in <(_Field, String)>[
              (_Field.upper, context.tr('simplified_mode.upper')),
              (_Field.lower, context.tr('simplified_mode.lower')),
            ]) ...<Widget>[
              if (field == _Field.lower) const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: _upperOrLower == field,
                  label: label,
                  child: GestureDetector(
                    onTap: () => setState(() => _upperOrLower = field),
                    child: _ValueCard(
                      value: _values[field]!,
                      unit: label,
                      active: _upperOrLower == field,
                      small: true,
                    ),
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
      _Keypad(onDigit: _type, onErase: _erase),
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

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.value,
    required this.unit,
    required this.active,
    this.small = false,
  });

  final String value;
  final String unit;
  final bool active;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SimplifiedStyle.surface,
        borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
        border: Border.all(
          color: active ? SimplifiedStyle.ink : SimplifiedStyle.disabled,
          width: active ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (small)
            Text(
              unit,
              style: SimplifiedStyle.text(
                SimplifiedStyle.caption,
                weight: AppTextTheme.medium,
              ),
            ),
          // Numbers read left to right in Arabic too.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value.isEmpty ? '–' : value,
              style: SimplifiedStyle.head(
                small ? SimplifiedStyle.number : 60,
                height: 1.1,
              ),
            ),
          ),
          if (!small)
            Text(unit, style: SimplifiedStyle.text(SimplifiedStyle.caption)),
        ],
      ),
    );
  }
}

/// A phone-style keypad: 1 to 9, then 0 and «حذف».
class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onErase});

  final ValueChanged<String> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget label, VoidCallback onTap, {bool quiet = false}) =>
        Material(
          color: quiet ? SimplifiedStyle.clear : SimplifiedStyle.surface,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Center(child: label),
          ),
        );
    Text digit(String value) => Text(value, style: SimplifiedStyle.head(28));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: <Widget>[
          for (final String value in const <String>[
            '1', '2', '3', '4', '5', '6', '7', '8', '9', //
          ])
            key(digit(value), () => onDigit(value)),
          const SizedBox.shrink(),
          key(digit('0'), () => onDigit('0')),
          key(
            Semantics(
              label: context.tr('simplified_mode.erase_digit'),
              excludeSemantics: true,
              child: const Icon(AppIcons.back, size: 28),
            ),
            onErase,
            quiet: true,
          ),
        ],
      ),
    );
  }
}
