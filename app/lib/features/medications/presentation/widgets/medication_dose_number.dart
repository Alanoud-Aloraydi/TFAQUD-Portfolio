import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/core/widgets/layout/inset_field_row.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_border.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Between the stepper's buttons: the dose, typed in western digits
/// whatever the keyboard sends and centred in a narrow field, then its
/// unit.
class MedicationDoseNumber extends StatelessWidget {
  const MedicationDoseNumber({
    super.key,
    required this.data,
    required this.units,
    required this.onChanged,
    required this.focusNode,
  });

  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;
  final FocusNode focusNode;

  /// Room for «0.5» or «10» at the title size.
  static const double _width = 48;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: _width,
          child: TextField(
            controller: data.doseController,
            focusNode: focusNode,
            onChanged: (_) => onChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: text.titleMedium,
            inputFormatters: <TextInputFormatter>[
              const WesternDigitsFormatter(decimal: true),
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: insetFieldDecoration(text, null),
          ),
        ),
        MedicationDoseUnit(data: data, units: units, onChanged: onChanged),
      ],
    );
  }
}

/// The start of a medicine's plan or record card: its photo, or a pill when
/// it has none, at the size every kind of card uses for its leading visual.
class MedicationLeading extends StatelessWidget {
  const MedicationLeading({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) => MedicationPhotoBuilder(
    circleId: circleId,
    planId: planId,
    builder: (BuildContext context, bytes) => bytes == null
        ? Container(
            width: AppItemCard.leading,
            height: AppItemCard.leading,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppSemanticColors.surfaceContent,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: const Icon(
              TafaqodPhosphorIcons.pill,
              color: AppSemanticColors.textSupporting,
            ),
          )
        : MedicationPhotoImage(
            bytes: bytes,
            width: AppItemCard.leading,
            height: AppItemCard.leading,
          ),
  );
}

/// The dose's unit after its number: one unit is a word; an injection
/// chooses between mL and units.
class MedicationDoseUnit extends StatelessWidget {
  const MedicationDoseUnit({
    super.key,
    required this.data,
    required this.units,
    required this.onChanged,
  });

  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final String unit = context.tr('medications.unit.${data.doseUnit.name}');
    if (units.length < 2) {
      return Text(unit, style: Theme.of(context).textTheme.bodyLarge);
    }
    return InsetChoiceButton(
      label: unit,
      semanticLabel: '${context.tr('medications.dose_unit')}: $unit',
      onPressed: () => _choose(context),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final DoseUnit? chosen = await chooseDoseUnit(
      context,
      units: units,
      selected: data.doseUnit,
    );
    if (chosen == null) return;
    data.doseUnit = chosen;
    onChanged();
  }
}

/// «وحدة الجرعة»: the unit an injection or a syrup is measured in, when the
/// medicine has more than one.
Future<DoseUnit?> chooseDoseUnit(
  BuildContext context, {
  required List<DoseUnit> units,
  required DoseUnit selected,
}) {
  return showOptionSheet<DoseUnit>(
    context,
    title: context.tr('medications.dose_unit'),
    options: units,
    labelOf: (DoseUnit unit) => context.tr('medications.unit.${unit.name}'),
    selected: selected,
  );
}
