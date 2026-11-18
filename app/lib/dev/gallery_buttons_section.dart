import 'package:app/core/constants/app_icons.dart';
import 'package:app/dev/gallery_section.dart';
import 'package:flutter/material.dart';

/// The buttons of the gallery.
class GalleryButtonsSection extends StatelessWidget {
  const GalleryButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Buttons',
      children: <Widget>[
        FilledButton(onPressed: () {}, child: const Text('Primary')),
        const FilledButton(onPressed: null, child: Text('Disabled')),
        OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
        TextButton(onPressed: () {}, child: const Text('Text link')),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(ActionIcons.plus),
          label: const Text('With icon'),
        ),
      ],
    );
  }
}
