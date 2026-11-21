import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_field_decoration.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_unit.dart';
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
