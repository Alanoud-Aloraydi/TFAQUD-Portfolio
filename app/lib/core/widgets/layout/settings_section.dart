import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
