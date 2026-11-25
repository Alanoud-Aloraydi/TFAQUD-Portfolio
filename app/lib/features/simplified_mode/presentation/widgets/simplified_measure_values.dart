import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_scaffold.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The number being typed: one big card for glucose, or the upper and the
/// lower card one under the other, where a tap chooses which one the
/// keypad fills.
Widget simplifiedMeasureValues(
  BuildContext context,
  SimplifiedMeasureForm form, {
  required bool glucose,
  required ValueChanged<SimplifiedMeasureField> onPick,
}) {
  if (glucose) {
    return SimplifiedMeasureValueCard(
      value: form.values[SimplifiedMeasureField.glucose]!,
      unit: context.tr('measurements.glucose_unit'),
      active: true,
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final (SimplifiedMeasureField field, String label)
          in <(SimplifiedMeasureField, String)>[
            (SimplifiedMeasureField.upper, context.tr('simplified_mode.upper')),
            (SimplifiedMeasureField.lower, context.tr('simplified_mode.lower')),
          ]) ...<Widget>[
        if (field == SimplifiedMeasureField.lower) const SizedBox(height: 8),
        Semantics(
          button: true,
          selected: form.upperOrLower == field,
          label: spoken(label),
          child: GestureDetector(
            onTap: () => onPick(field),
            child: SimplifiedMeasureValueCard(
              value: form.values[field]!,
              unit: label,
              active: form.upperOrLower == field,
              small: true,
            ),
          ),
        ),
      ],
    ],
  );
}

/// The reading [form] holds, or null while one of its numbers is missing.
/// The note travels only with «أخرى».
SimplifiedReading? simplifiedMeasureReading(SimplifiedMeasureForm form) {
  final MeasurementKind? kind = form.kind;
  if (kind == null) return null;
  final bool glucose = kind == MeasurementKind.glucose;
  final int? one = int.tryParse(
    form.values[glucose
        ? SimplifiedMeasureField.glucose
        : SimplifiedMeasureField.upper]!,
  );
  final int? two = glucose
      ? null
      : int.tryParse(form.values[SimplifiedMeasureField.lower]!);
  if (one == null || (!glucose && two == null)) return null;
  final String note = form.note.text.trim();
  return SimplifiedReading(
    kind: kind,
    valueOne: one,
    valueTwo: two,
    conditions: form.conditions,
    note: form.conditions.contains('other') && note.isNotEmpty ? note : null,
  );
}

/// Why a typed reading was refused, as a key in assets/translations.
String simplifiedInvalidReadingKey(SimplifiedReading? reading) =>
    reading?.kind == MeasurementKind.bp
    ? 'simplified_mode.invalid_bp'
    : 'measurements.invalid_reading';

/// One typed measurement, read out as a single value: the number large and
/// its unit, in a [SimplifiedMeasureFrame]. A [small] card is one of a blood
/// pressure's two numbers, its name at the start and the number at the end.
class SimplifiedMeasureValueCard extends StatelessWidget {
  const SimplifiedMeasureValueCard({
    super.key,
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
    final Widget unitText = Text(
      unit,
      style: SimplifiedStyle.text(
        small ? SimplifiedStyle.body : SimplifiedStyle.caption,
        weight: small ? AppTextTheme.medium : AppTextTheme.regular,
      ),
    );
    // Numbers read left to right in Arabic too.
    final Widget number = Text(
      value.isEmpty ? '–' : value,
      textDirection: TextDirection.ltr,
      style: SimplifiedStyle.head(
        small ? SimplifiedStyle.number : 60,
        height: 1.1,
      ),
    );
    return Semantics(
      liveRegion: active,
      label: spoken(
        context.tr(
          'simplified_mode.a11y.typed_value',
          args: <String>[value.isEmpty ? unit : '$value $unit'],
        ),
      ),
      excludeSemantics: true,
      child: SimplifiedMeasureFrame(
        active: active,
        small: small,
        child: small
            ? Row(
                children: <Widget>[
                  Expanded(child: unitText),
                  number,
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[number, unitText],
              ),
      ),
    );
  }
}
