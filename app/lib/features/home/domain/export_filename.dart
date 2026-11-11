import 'package:app/features/home/domain/export_period.dart';

/// The name of the exported file: «`tafaqod-<patient>-<from>-<to>.pdf`», with
/// only letters and digits (Arabic or Latin) so every share target accepts it.
String exportFilename(String? patientName, ExportPeriod period) {
  final String safe = (patientName ?? 'record').trim().replaceAll(
    RegExp(r'[^A-Za-z0-9؀-ۿ]+'),
    '-',
  );
  return 'tafaqod-$safe-${_day(period.start)}-${_day(period.end)}.pdf';
}

String _day(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
