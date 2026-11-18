import 'package:app/features/home/domain/entities/record_pdf_row.dart';
import 'package:app/features/home/domain/entities/record_pdf_section.dart';

/// The whole file: the app name and [title] at the top, the [header] lines
/// (patient, period, time zone, export date), then the [sections] in order.
class RecordPdfDocument {
  const RecordPdfDocument({
    required this.appName,
    required this.title,
    required this.header,
    required this.sections,
  });

  final String appName;
  final String title;
  final List<RecordPdfRow> header;
  final List<RecordPdfSection> sections;
}
