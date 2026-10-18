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

  static const List<IconData> _icons = <IconData>[
    Icons.chevron_left,
    Icons.check,
    Icons.add,
    Icons.notifications_none,
    Icons.person_outline,
    Icons.people_outline,
    Icons.info_outline,
    Icons.warning_amber,
    Icons.schedule,
    Icons.calendar_today,
    Icons.medication,
    Icons.favorite_border,
    Icons.water_drop,
    Icons.search,
    Icons.delete_outline,
    Icons.edit,
    Icons.share,
  ];

  /// Calls GET /health and shows the address used and the result.
  Future<void> _checkApi() async {
    setState(() {
      _apiBusy = true;
      _apiStatus = '';
    });
    String status;
    try {
      final Response<dynamic> response = await GetIt.I<DioClient>().get(
        ApiEndpoints.health,
      );
      status =
          'GET ${ApiEndpoints.baseUrl}${ApiEndpoints.health}\n'
          'HTTP ${response.statusCode}';
    } catch (error) {
      final Failure failure = FailureExceptions.getException(error);
      status = '${failure.messageKey.tr()} (${error.runtimeType})';
    }
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
          _Section(
            title: 'Buttons',
            children: <Widget>[
              FilledButton(onPressed: () {}, child: const Text('Primary')),
              const FilledButton(onPressed: null, child: Text('Disabled')),
              OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
              TextButton(onPressed: () {}, child: const Text('Text link')),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('With icon'),
              ),
            ],
          ),
          _Section(
            title: 'Text fields',
            children: const <Widget>[
              TextField(decoration: InputDecoration(labelText: 'Label', hintText: 'Hint')),
              TextField(decoration: InputDecoration(labelText: 'Label', errorText: 'Required field')),
              TextField(decoration: InputDecoration(labelText: '\u0627\u0644\u0627\u0633\u0645', hintText: '\u0645\u0631\u062D\u0628\u0627')),
            ],
          ),
          _Section(
            title: 'Chips',
            children: <Widget>[
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (int i = 0; i < 3; i++)
                    ChoiceChip(
                      label: Text('Option ${i + 1}'),
                      selected: _chip == i,
                      onSelected: (_) => setState(() => _chip = i),
                    ),
                ],
              ),
            ],
          ),
          _Section(
            title: 'Card',
            children: const <Widget>[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Card content'),
                ),
              ),
            ],
          ),
          _Section(
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
          ),
          _Section(
            title: 'Icons (Material)',
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  for (final IconData icon in _icons) Icon(icon, size: 28),
                ],
              ),
            ],
          ),
          _Section(
            title: 'API',
            children: <Widget>[
              FilledButton(
                onPressed: _apiBusy ? null : _checkApi,
                child: const Text('GET /health'),
              ),
              if (_apiStatus.isNotEmpty) Text(_apiStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

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
