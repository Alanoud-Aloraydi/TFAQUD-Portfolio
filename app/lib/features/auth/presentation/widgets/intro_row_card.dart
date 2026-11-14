import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/material.dart';

/// A white card with an icon tile, two lines and a pill at the end.
class IntroRowCard extends StatelessWidget {
  const IntroRowCard({
    super.key,
    required this.tile,
    required this.title,
    required this.note,
    required this.trailing,
  });

  final Widget tile;
  final String title;
  final String note;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.floating(AppRadius.m),
      child: Row(
        children: <Widget>[
          tile,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleSmall),
                Text(note, style: text.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
