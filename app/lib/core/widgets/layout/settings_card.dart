import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/material.dart';

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
