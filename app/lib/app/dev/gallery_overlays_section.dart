import 'package:app/app/dev/gallery_buttons_section.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The dialog and the bottom sheet of the gallery.
class GalleryOverlaysSection extends StatelessWidget {
  const GalleryOverlaysSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Dialog and bottom sheet',
      children: <Widget>[
        FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => AlertDialog(
              title: const Text('Title'),
              content: const Text('Dialog body text.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          child: const Text('Open dialog'),
        ),
        OutlinedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext ctx) => const SizedBox(
              height: 200,
              child: Center(child: Text('Bottom sheet')),
            ),
          ),
          child: const Text('Open bottom sheet'),
        ),
      ],
    );
  }
}

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
