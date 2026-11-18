import 'package:app/dev/gallery_section.dart';
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
