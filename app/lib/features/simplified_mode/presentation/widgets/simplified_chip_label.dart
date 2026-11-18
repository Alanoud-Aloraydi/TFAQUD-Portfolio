import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// A chip's text, with a check beside it once it is the one chosen.
class SimplifiedChipLabel extends StatelessWidget {
  const SimplifiedChipLabel(
    this.text, {
    super.key,
    required this.selected,
    required this.onDark,
  });

  final String text;
  final bool selected;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          text,
          style: SimplifiedStyle.label(
            SimplifiedStyle.caption,
            color: onDark ? SimplifiedColors.surface : SimplifiedColors.ink,
          ),
        ),
        if (selected) ...<Widget>[
          const SizedBox(width: 6),
          const ExcludeSemantics(child: Icon(ActionIcons.check, size: 18)),
        ],
      ],
    );
  }
}
