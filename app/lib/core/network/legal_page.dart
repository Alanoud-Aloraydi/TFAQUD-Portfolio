import 'package:app/core/network/api_endpoints.dart';
import 'package:url_launcher/url_launcher.dart';

/// The Arabic pages the server shows to anyone (backend/app/legal/): the
/// app opens them from the welcome and from «حسابي».
enum LegalPage {
  privacy('privacy'),
  terms('terms');

  const LegalPage(this.path);

  final String path;

  /// This page on the server the app calls, outside [ApiEndpoints.prefix].
  Uri get uri {
    final String api = ApiEndpoints.baseUrl;
    final String host = api.substring(
      0,
      api.length - ApiEndpoints.prefix.length,
    );
    return Uri.parse('$host/$path');
  }

  /// Opens it in a browser view over the app.
  Future<bool> open() => launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}
