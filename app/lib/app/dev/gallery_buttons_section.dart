import 'package:app/core/constants/app_icons.dart';
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

/// A titled group of sample widgets in the gallery.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: children),
        ],
      ),
    );
  }
}
