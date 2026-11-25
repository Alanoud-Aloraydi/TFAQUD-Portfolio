import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_saved.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_values.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_segmented.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «تسجيل قياس» as a page: the body of the moment, and «حفظ القياس» at
/// the bottom once there is a form to save.
Widget simplifiedMeasurePage(
  BuildContext context,
  SimplifiedMeasurementState state,
  SimplifiedMeasureForm form, {
  required VoidCallback onChanged,
  required VoidCallback onSave,
}) {
  final MeasurementKind? kind = form.kind;
  final bool ready =
      state.status == SimplifiedMeasurementStatus.ready && kind != null;
  return SimplifiedPage(
    title: context.tr('simplified_mode.measure_title'),
    backKey: 'simplified_mode.close',
    // A failure or a missing target is read too, not only the form.
    footer: ready
        ? SimplifiedButton(
            label: context.tr('simplified_mode.save_reading'),
            onPressed: state.saving || simplifiedMeasureReading(form) == null
                ? null
                : onSave,
          )
        : null,
    children: simplifiedMeasureBody(context, state, form, onChanged: onChanged),
  );
}

/// What «تسجيل قياس» shows: a spinner while it loads, the reason and
/// «حاول مرة أخرى» after a failure, «لا يوجد قياس» when there is nothing
/// to record, and otherwise the form with the last readings under it.
List<Widget> simplifiedMeasureBody(
  BuildContext context,
  SimplifiedMeasurementState state,
  SimplifiedMeasureForm form, {
  required VoidCallback onChanged,
}) {
  final MeasurementKind? kind = form.kind;
  return switch (state.status) {
    SimplifiedMeasurementStatus.loading => const <Widget>[LoadingNote()],
    SimplifiedMeasurementStatus.failure => <Widget>[
      simplifiedMeasureMessage(context, state.messageKey ?? 'error.unknown'),
      SimplifiedButton(
        label: context.tr('simplified_mode.try_again'),
        onPressed: context.read<SimplifiedMeasurementCubit>().load,
      ),
    ],
    SimplifiedMeasurementStatus.ready when kind == null => <Widget>[
      simplifiedMeasureMessage(context, 'simplified_mode.no_target'),
    ],
    SimplifiedMeasurementStatus.ready => <Widget>[
      ...simplifiedMeasureFormRows(
        context,
        state,
        form,
        kind!,
        onChanged: onChanged,
      ),
      const SizedBox(height: SimplifiedStyle.gap),
      SimplifiedRecentReadings(
        readings: state.recent,
        kind: kind,
        now: PatientClockScope.of(context).now(),
      ),
    ],
  };
}

/// A plain sentence in place of the form: a failure, or nothing to record.
Widget simplifiedMeasureMessage(BuildContext context, String key) => Text(
  context.tr(key),
  style: SimplifiedStyle.text(
    SimplifiedStyle.body,
    color: SimplifiedColors.ink,
  ),
);

/// Which number the keypad types into.
enum SimplifiedMeasureField { glucose, upper, lower }

/// The form of «تسجيل قياس»: the kind to record when there is a choice,
/// the typed number, the hint under it, the keypad, and the circumstances.
List<Widget> simplifiedMeasureFormRows(
  BuildContext context,
  SimplifiedMeasurementState state,
  SimplifiedMeasureForm form,
  MeasurementKind kind, {
  required VoidCallback onChanged,
}) => <Widget>[
  if (state.kinds.length > 1)
    SimplifiedSegmented<MeasurementKind>(
      segments: <MeasurementKind, String>{
        for (final MeasurementKind item in state.kinds)
          item: context.tr('measurements.${item.name}'),
      },
      selected: kind,
      onChanged: (value) {
        form.show(state, value);
        onChanged();
      },
    ),
  simplifiedMeasureValues(
    context,
    form,
    glucose: kind == MeasurementKind.glucose,
    onPick: (field) {
      form.upperOrLower = field;
      onChanged();
    },
  ),
  simplifiedMeasureHint(context, form, kind),
  SimplifiedMeasureKeypad(
    onDigit: (digit) {
      form.type(digit);
      onChanged();
    },
    onErase: () {
      form.erase();
      onChanged();
    },
  ),
  simplifiedMeasureConditions(context, form, kind: kind, onChanged: onChanged),
];

/// What to type next, under the number, in red once a reading was refused.
Widget simplifiedMeasureHint(
  BuildContext context,
  SimplifiedMeasureForm form,
  MeasurementKind kind,
) => Text(
  context.tr(form.errorKey ?? _hintKey(form, kind)),
  textAlign: TextAlign.center,
  style: SimplifiedStyle.text(
    SimplifiedStyle.body,
    color: form.errorKey == null
        ? SimplifiedColors.muted
        : SimplifiedColors.danger,
    weight: AppTextTheme.medium,
  ),
);

String _hintKey(SimplifiedMeasureForm form, MeasurementKind kind) =>
    kind == MeasurementKind.glucose
    ? 'simplified_mode.type_glucose'
    : form.upperOrLower == SimplifiedMeasureField.upper
    ? 'simplified_mode.type_upper'
    : 'simplified_mode.type_lower';

/// A phone-style keypad: 1 to 9, then 0 and «حذف», drawn as the delete
/// key every phone keyboard has (⌫), not as an arrow that reads «رجوع».
class SimplifiedMeasureKeypad extends StatelessWidget {
  const SimplifiedMeasureKeypad({
    super.key,
    required this.onDigit,
    required this.onErase,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget label, VoidCallback onTap, {bool quiet = false}) =>
        Material(
          color: quiet ? SimplifiedColors.clear : SimplifiedColors.surface,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Center(child: label),
          ),
        );
    Widget digit(String value) => Semantics(
      label: spoken(
        context.tr('simplified_mode.a11y.digit', args: <String>[value]),
      ),
      excludeSemantics: true,
      child: Text(value, style: SimplifiedStyle.head(28)),
    );
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
              label: spoken(context.tr('simplified_mode.erase_digit')),
              excludeSemantics: true,
              child: const Icon(CupertinoIcons.delete_left, size: 32),
            ),
            onErase,
            quiet: true,
          ),
        ],
      ),
    );
  }
}

/// «ظروف القياس»: what it is for, the chips, and the note field once
/// «أخرى» is among them.
Widget simplifiedMeasureConditions(
  BuildContext context,
  SimplifiedMeasureForm form, {
  required MeasurementKind kind,
  required VoidCallback onChanged,
}) => Column(
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
    simplifiedMeasureChips(context, form, kind: kind, onChanged: onChanged),
    if (form.conditions.contains('other')) ...<Widget>[
      const SizedBox(height: 12),
      simplifiedMeasureNote(context, form),
    ],
  ],
);

/// The free note «أخرى» asks for, 250 characters at most.
Widget simplifiedMeasureNote(
  BuildContext context,
  SimplifiedMeasureForm form,
) => TextField(
  controller: form.note,
  maxLength: 250,
  inputFormatters: const [CodePointLengthFormatter(250)],
  style: SimplifiedStyle.text(
    SimplifiedStyle.body,
    color: SimplifiedColors.ink,
    weight: AppTextTheme.medium,
  ),
  decoration: InputDecoration(
    hintText: context.tr('simplified_mode.other_hint'),
    filled: true,
    fillColor: SimplifiedColors.surface,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: SimplifiedColors.ink, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: SimplifiedColors.ink, width: 2),
    ),
  ),
);
