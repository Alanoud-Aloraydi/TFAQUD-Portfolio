import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:flutter/material.dart';

/// A field that opens a picker when tapped (the birth date and the city). Its
/// label is above it, like [LabeledTextField]. [value] is null until the user
/// picks, and the field then shows [hint].
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.errorText,
  });

  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? value;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasError = errorText != null;
    final BorderRadius radius = BorderRadius.circular(AppRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.titleSmall?.copyWith(color: AppColors.ink2)),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: label,
          value: value ?? hint,
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: hasError ? AppColors.danger : AppColors.fieldBorder,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: RoundedRectangleBorder(borderRadius: radius),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        value ?? hint,
                        style: value == null
                            ? text.bodyLarge?.copyWith(color: AppColors.ink3)
                            : text.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(icon, size: 22, color: AppColors.ink2),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: text.bodySmall?.copyWith(color: AppColors.dangerInk),
          ),
        ],
      ],
    );
  }
}
