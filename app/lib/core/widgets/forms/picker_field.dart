import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:flutter/material.dart';

/// A field that opens a picker when tapped (the birth date and the city), in
/// the design system's form row: the small label on the right, the value (or
/// [hint] until the user picks) right after it, and [icon] at the end.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.errorText,
    this.note,
  });

  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? value;
  final String? errorText;

  /// A line under the field, such as a birth date in the other calendar.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      footer: note,
      children: <Widget>[
        InsetRow(
          label: label,
          value: value,
          placeholder: hint,
          onTap: onTap,
          errorText: errorText,
          trailing: Icon(
            icon,
            size: AppSizes.iconSmall,
            color: AppSemanticColors.borderControlBase,
          ),
        ),
      ],
    );
  }
}
