import 'package:app/dev/gallery_section.dart';
import 'package:flutter/material.dart';

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
