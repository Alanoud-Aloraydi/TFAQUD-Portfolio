import 'package:app/dev/gallery_section.dart';
import 'package:flutter/material.dart';

/// The text fields of the gallery.
class GalleryFieldsSection extends StatelessWidget {
  const GalleryFieldsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Text fields',
      children: const <Widget>[
        TextField(
          decoration: InputDecoration(labelText: 'Label', hintText: 'Hint'),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: 'Label',
            errorText: 'Required field',
          ),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: '\u0627\u0644\u0627\u0633\u0645',
            hintText: '\u0645\u0631\u062D\u0628\u0627',
          ),
        ),
      ],
    );
  }
}
