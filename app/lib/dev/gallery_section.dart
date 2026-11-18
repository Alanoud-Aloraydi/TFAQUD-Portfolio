import 'package:flutter/material.dart';

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
