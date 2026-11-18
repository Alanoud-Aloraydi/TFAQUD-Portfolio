import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «إضافة دائرة» as the capsule itself, for an account with no circle yet.
/// Nothing is drawn while [onPressed] is null (the home data is loading).
class AddCircleCapsule extends StatelessWidget {
  const AddCircleCapsule({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();
    final String add = context.tr('topbar.add_circle');
    return GlassCapsuleButton(
      label: add,
      semanticLabel: add,
      icon: ActionIcons.plus,
      onPressed: onPressed,
    );
  }
}
