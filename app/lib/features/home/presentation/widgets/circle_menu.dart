import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the menu returns for «إضافة دائرة». Circle ids never look like it.
const String addCircleChoice = '\u0000add-circle';

/// The glass menu of the circle switcher, grown out of its capsule: every
/// circle, a check mark on [selectedId], and «إضافة دائرة» when
/// [canAddCircle]. Returns the id picked, [addCircleChoice], or null.
Future<String?> showCircleMenu(
  BuildContext context, {
  required List<CareCircleSummary> circles,
  required String selectedId,
  required String name,
  required bool canAddCircle,
}) => showGlassMenu<String>(
  anchorContext: context,
  semanticLabel: context.tr('topbar.circles_title'),
  // The capsule's own content, which blurs away as the glass grows.
  anchorContent: CircleMenuAnchor(name: name),
  sections: <List<GlassMenuItem<String>>>[
    <GlassMenuItem<String>>[
      for (final CareCircleSummary circle in circles)
        GlassMenuItem<String>(
          value: circle.id,
          label: circle.name,
          selected: circle.id == selectedId,
        ),
    ],
    if (canAddCircle)
      <GlassMenuItem<String>>[
        GlassMenuItem<String>(
          value: addCircleChoice,
          label: context.tr('topbar.add_circle'),
          icon: ActionIcons.plus,
        ),
      ],
  ],
);

/// The circle switcher capsule's own content, drawn at the top of its menu:
/// the circle's name and the down chevron.
class CircleMenuAnchor extends StatelessWidget {
  const CircleMenuAnchor({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Flexible(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      const Icon(
        ArrowIcons.caretDown,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.textPrimary,
      ),
    ],
  );
}
