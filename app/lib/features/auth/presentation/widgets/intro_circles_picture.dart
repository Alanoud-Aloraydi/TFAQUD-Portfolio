import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_menu_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Page 1: the circle switcher of the top bar, open on three circles.
class IntroCirclesPicture extends StatelessWidget {
  const IntroCirclesPicture({super.key});

  @override
  Widget build(BuildContext context) {
    final String khalid = context.tr('intro.demo.khalid_circle');
    Widget row(String label, [IconData? icon]) => GlassMenuRow(
      entry: GlassMenuEntry(
        value: label,
        label: label,
        icon: icon,
        selected: label == khalid,
      ),
      height: GlassMenuLayout.rowHeight(context),
    );
    return Column(
      spacing: AppSpacing.md,
      children: <Widget>[
        GlassCapsuleButton(
          label: khalid,
          semanticLabel: khalid,
          icon: ArrowIcons.caretDown,
          onPressed: null,
          leading: PersonPhoto(
            name: khalid,
            photoPath: '',
            avatarCode: 'gh_3',
            size: 26,
          ),
        ),
        GlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: <Widget>[
                row(khalid),
                row(context.tr('intro.demo.noura_circle')),
                row(context.tr('intro.demo.my_care')),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                row(context.tr('topbar.add_circle'), ActionIcons.plus),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
