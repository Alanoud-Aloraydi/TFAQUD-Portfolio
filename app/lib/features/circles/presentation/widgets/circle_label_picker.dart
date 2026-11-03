import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "الدائرة تُسمى": the chips of the words a circle can be named with ("أمي",
/// "أبي"...), the text field that opens under "اسم آخر", and a hint line that
/// shows how the circle will appear. Shared by the page that creates a circle
/// for a patient without the app and the page that sends a request.
class CircleLabelPicker extends StatelessWidget {
  const CircleLabelPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.customController,
    required this.onCustomChanged,
    required this.hint,
    this.customError,
  });

  final CircleLabel selected;
  final ValueChanged<CircleLabel> onSelected;

  /// The field for the typed word, shown only when [selected] is
  /// [CircleLabel.other].
  final TextEditingController customController;
  final ValueChanged<String> onCustomChanged;

  /// The line under the chips, already translated.
  final String hint;

  /// Shown under the typed word when it is missing.
  final String? customError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsetText.header(context.tr('circles.label_title')),
        const SizedBox(height: AppSpacing.sm),
        OptionChips(
          options: <ChipOption>[
            for (final CircleLabel label in CircleLabel.values)
              ChipOption(label.name, context.tr('circles.label.${label.name}')),
          ],
          isSelected: (String code) => code == selected.name,
          onTap: (String code) => onSelected(CircleLabel.values.byName(code)),
        ),
        if (selected == CircleLabel.other) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          LabeledTextField(
            label: context.tr('circles.custom_label'),
            controller: customController,
            maxLength: CircleNames.maxLabelLength,
            textInputAction: TextInputAction.done,
            onChanged: onCustomChanged,
            errorText: customError,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        InsetText.note(hint),
      ],
    );
  }
}

/// The hint line under the chips. With a first name it shows the circle name as
/// it will appear ("تظهر باسم: أمي نورة"); without one it explains the rule.
String circleLabelHint(
  BuildContext context, {
  required CircleLabel label,
  required String customLabel,
  String firstName = '',
}) {
  final String word = label == CircleLabel.other
      ? customLabel.trim()
      : context.tr('circles.label.${label.name}');
  if (word.isEmpty) return context.tr('circles.label_hint_custom');
  if (firstName.trim().isEmpty) {
    return context.tr('circles.label_hint', args: <String>[word]);
  }
  return context.tr(
    'circles.name_preview',
    args: <String>[CircleNames.compose(word, firstName)],
  );
}
