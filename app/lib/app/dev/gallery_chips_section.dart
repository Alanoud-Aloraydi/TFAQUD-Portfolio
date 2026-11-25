import 'package:app/app/dev/gallery_buttons_section.dart';
import 'package:flutter/material.dart';

/// The chips of the gallery.
class GalleryChipsSection extends StatelessWidget {
  const GalleryChipsSection({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Chips',
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              ChoiceChip(
                label: Text('Option ${i + 1}'),
                selected: selected == i,
                onSelected: (_) => onSelected(i),
              ),
          ],
        ),
      ],
    );
  }
}

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

/// The API check of the gallery.
class GalleryApiSection extends StatelessWidget {
  const GalleryApiSection({
    super.key,
    required this.busy,
    required this.status,
    required this.onCheck,
  });

  final bool busy;
  final String status;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'API',
      children: <Widget>[
        FilledButton(
          onPressed: busy ? null : onCheck,
          child: const Text('GET /health'),
        ),
        if (status.isNotEmpty) Text(status),
      ],
    );
  }
}
