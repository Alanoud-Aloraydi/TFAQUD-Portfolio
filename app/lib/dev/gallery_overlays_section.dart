import 'package:app/dev/gallery_section.dart';
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
