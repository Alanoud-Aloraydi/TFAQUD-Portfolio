import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:flutter/material.dart';

/// The small rounded square with an icon at the start of a settings row,
/// as in iOS Settings: it tells the rows apart at a glance. Decorative: the
/// row's label says what it is.
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({
    super.key,
    required this.icon,
    required this.background,
  });

  /// iOS Settings' icon square: 29 points, its corners about a quarter.
  static const double size = 30;
  static const double radius = 8;

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconSmall,
          color: AppSettingsTileColors.onTile,
        ),
      ),
    );
  }
}

/// A white card whose rows are separated by thin lines.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppSurfaces.card(),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: AppSizes.divider,
                indent: 16,
                endIndent: 16,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A small grey title above a white card, as the account page groups its rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitle(title),
        SettingsCard(children: children),
      ],
    );
  }
}
