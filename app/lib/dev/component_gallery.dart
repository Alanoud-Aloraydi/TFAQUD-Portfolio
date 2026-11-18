import 'package:app/dev/gallery_api_check.dart';
import 'package:app/dev/gallery_api_section.dart';
import 'package:app/dev/gallery_buttons_section.dart';
import 'package:app/dev/gallery_card_section.dart';
import 'package:app/dev/gallery_chips_section.dart';
import 'package:app/dev/gallery_fields_section.dart';
import 'package:app/dev/gallery_icons_section.dart';
import 'package:app/dev/gallery_overlays_section.dart';
import 'package:flutter/material.dart';

/// Development-only page that shows the shared components and checks the
/// connection to the API. It is registered in the router only when kDebugMode
/// is true.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  int _chip = 0;
  String _apiStatus = '';
  bool _apiBusy = false;

  Future<void> _checkApi() async {
    setState(() {
      _apiBusy = true;
      _apiStatus = '';
    });
    final String status = await checkGalleryApi();
    if (!mounted) return;
    setState(() {
      _apiBusy = false;
      _apiStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const GalleryButtonsSection(),
          const GalleryFieldsSection(),
          GalleryChipsSection(
            selected: _chip,
            onSelected: (int i) => setState(() => _chip = i),
          ),
          const GalleryCardSection(),
          const GalleryOverlaysSection(),
          const GalleryIconsSection(),
          GalleryApiSection(
            busy: _apiBusy,
            status: _apiStatus,
            onCheck: _checkApi,
          ),
        ],
      ),
    );
  }
}
