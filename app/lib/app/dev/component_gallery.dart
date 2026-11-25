import 'package:app/app/dev/gallery_buttons_section.dart';
import 'package:app/app/dev/gallery_chips_section.dart';
import 'package:app/app/dev/gallery_overlays_section.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:dio/dio.dart' show Response;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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

/// Calls GET /health and returns the address used and the result.
Future<String> checkGalleryApi() async {
  try {
    final Response<dynamic> response = await GetIt.I<DioClient>().get(
      ApiEndpoints.health,
    );
    return 'GET ${ApiEndpoints.baseUrl}${ApiEndpoints.health}\n'
        'HTTP ${response.statusCode}';
  } catch (error) {
    final Failure failure = FailureExceptions.getException(error);
    return '${failure.messageKey.tr()} (${error.runtimeType})';
  }
}
