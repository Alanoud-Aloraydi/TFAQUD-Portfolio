import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/dev/gallery_section.dart';
import 'package:flutter/material.dart';

/// The icons of the gallery.
class GalleryIconsSection extends StatelessWidget {
  const GalleryIconsSection({super.key});

  static const List<IconData> _icons = <IconData>[
    ArrowIcons.back,
    ActionIcons.check,
    ActionIcons.plus,
    NoticeIcons.bell,
    PeopleIcons.user,
    PeopleIcons.users,
    NoticeIcons.info,
    NoticeIcons.warning,
    ScheduleIcons.clock,
    ScheduleIcons.calendar,
    CareIcons.pill,
    CareIcons.heart,
    CareIcons.drop,
    ActionIcons.search,
    ActionIcons.trash,
    ActionIcons.pencil,
    NoticeIcons.export,
  ];

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Icons (Material)',
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            for (final IconData icon in _icons) Icon(icon, size: AppSizes.icon),
          ],
        ),
      ],
    );
  }
}
