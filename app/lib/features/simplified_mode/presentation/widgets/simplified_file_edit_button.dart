import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// «✎ تعديل» beside the title, which opens the detailed mode's edit page
/// inside this mode. The pencil and the fill are the app's one edit
/// affordance (`EditAction`), at this mode's size.
class SimplifiedFileEditButton extends StatelessWidget {
  const SimplifiedFileEditButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(ActionIcons.pencil, size: SimplifiedStyle.caption),
    style: FilledButton.styleFrom(
      backgroundColor: SimplifiedColors.accentTint,
      foregroundColor: SimplifiedColors.ink,
      minimumSize: const Size(0, SimplifiedStyle.touch),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    label: Text(
      context.tr('simplified_mode.file.edit'),
      style: SimplifiedStyle.head(SimplifiedStyle.caption),
    ),
  );
}
