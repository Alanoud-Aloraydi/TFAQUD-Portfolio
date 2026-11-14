import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

class AccountNameEditField extends StatelessWidget {
  const AccountNameEditField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
      const SizedBox(height: AppSpacing.labelGap),
      TextField(
        controller: controller,
        maxLength: NameLimits.name,
        textAlign: TextAlign.start,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        decoration: InputDecoration(
          // White with a line edge, from the theme, so the field shows on
          // the page.
          counterText: '',
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
        ),
      ),
    ],
  );
}
