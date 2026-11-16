import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «تعديل» beside the title, which opens the detailed mode's edit page
/// inside this mode.
class SimplifiedFileEditButton extends StatelessWidget {
  const SimplifiedFileEditButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: SimplifiedStyle.accentTint,
      foregroundColor: SimplifiedStyle.ink,
      minimumSize: const Size(0, SimplifiedStyle.touch),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    child: Text(
      context.tr('simplified_mode.file.edit'),
      style: SimplifiedStyle.head(SimplifiedStyle.caption),
    ),
  );
}
