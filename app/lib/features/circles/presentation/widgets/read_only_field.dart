import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:flutter/material.dart';

/// A field the person cannot change, shown on a grey background with a small
/// note on the far side that says where the value comes from ("من حسابك",
/// "حدده صاحب الطلب"). Its label is above it, like the other fields.
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.note,
    required this.child,
  });

  final String label;
  final String note;

  /// The value, or a spinner or a retry link while it loads.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.titleSmall?.copyWith(color: AppColors.ink2)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.sunken,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: child),
              const SizedBox(width: 12),
              Text(note, style: text.bodySmall?.copyWith(color: AppColors.ink3)),
            ],
          ),
        ),
      ],
    );
  }
}
