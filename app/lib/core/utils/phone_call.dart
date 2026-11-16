import 'package:url_launcher/url_launcher.dart';

/// Opens the phone app on a number, spaces and all.
Future<void> callNumber(String number) =>
    launchUrl(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));
