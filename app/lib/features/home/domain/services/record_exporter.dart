import 'package:app/features/home/domain/entities/record_pdf_model.dart';

/// Hands the finished record to the person, however the phone does that.
///
/// The screen composes a [RecordPdfDocument] and asks for it to be shared;
/// that it becomes a PDF is the data layer's business.
abstract class RecordExporter {
  /// [pageLabel] names each page («صفحة ١ من ٣»), which only the interface
  /// can word, and [filename] is what the person sees when saving it.
  Future<void> share({
    required RecordPdfDocument document,
    required String Function(int page, int pages) pageLabel,
    required String filename,
  });
}
