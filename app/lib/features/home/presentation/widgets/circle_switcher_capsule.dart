import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The capsule of the circle switcher: the patient's photo, the circle's
/// name and a down chevron.
class CircleSwitcherCapsule extends StatelessWidget {
  const CircleSwitcherCapsule({
    super.key,
    required this.selected,
    required this.onPressed,
  });

  final CareCircleSummary selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String name = selected.name;
    return GlassCapsuleButton(
      label: name,
      // Display only here: editing the patient's photo happens in the
      // circle tab, never from the switcher.
      leading: PersonPhoto(
        name: name,
        photoPath: CircleEndpoints.patientPhoto(selected.id),
        avatarCode: selected.patientAvatarCode,
        size: 26,
      ),
      semanticLabel: context.tr(
        'topbar.switch_circle',
        args: <String>[selected.name],
      ),
      icon: ArrowIcons.caretDown,
      onPressed: onPressed,
    );
  }
}

/// Opens the circle menu from the capsule of [selected] and does what is
/// picked: «إضافة دائرة», another circle, or nothing. [setMenuOpen] hides
/// the capsule while the menu is open; [isMounted] says whether the
/// capsule is still in the tree when the menu closes.
Future<void> chooseCircle(
  BuildContext context, {
  required List<CareCircleSummary> circles,
  required CareCircleSummary selected,
  required ValueChanged<String> onSelected,
  required VoidCallback? onAddCircle,
  required ValueChanged<bool> setMenuOpen,
  required bool Function() isMounted,
}) async {
  setMenuOpen(true);
  final String? picked = await showCircleMenu(
    context,
    circles: circles,
    selectedId: selected.id,
    name: selected.name,
    canAddCircle: onAddCircle != null,
  );
  if (!isMounted()) return;
  setMenuOpen(false);
  if (picked == null) return;
  if (picked == addCircleChoice) {
    onAddCircle?.call();
  } else if (picked != selected.id) {
    onSelected(picked);
  }
}

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
