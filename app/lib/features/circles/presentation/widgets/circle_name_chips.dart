import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «اسم الدائرة»: the ready names as chips, and the field that opens under
/// «أخرى» for a name of the person's own.
class CircleNameChips extends StatelessWidget {
  const CircleNameChips({
    super.key,
    required this.cubit,
    required this.state,
    required this.customName,
  });

  final CreateCircleCubit cubit;
  final CreateCircleState state;

  /// Holds the typed name while the page is open.
  final TextEditingController customName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsetText.header(context.tr('circles.circle_name')),
        const SizedBox(height: AppSpacing.sm),
        OptionChips(
          options: <ChipOption>[
            for (final NamePreset preset in NamePreset.values)
              ChipOption(
                preset.name,
                context.tr('circles.preset.${preset.name}'),
              ),
          ],
          isSelected: (String code) => code == state.namePreset.name,
          onTap: (String code) =>
              cubit.choosePreset(NamePreset.values.byName(code)),
        ),
        if (state.namePreset == NamePreset.other) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          LabeledTextField(
            label: context.tr('circles.custom_name'),
            controller: customName,
            maxLength: maxCustomNameLength,
            textInputAction: TextInputAction.done,
            onChanged: cubit.customNameChanged,
            errorText: state.showErrors && state.customName.trim().isEmpty
                ? context.tr('common.field_required')
                : null,
          ),
        ],
      ],
    );
  }
}
