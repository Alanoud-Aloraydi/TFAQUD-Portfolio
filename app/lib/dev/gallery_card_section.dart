import 'package:app/dev/gallery_section.dart';
import 'package:flutter/material.dart';

/// The card of the gallery.
class GalleryCardSection extends StatelessWidget {
  const GalleryCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Card',
      children: const <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Card content'),
          ),
        ),
      ],
    );
  }
}
