import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// One line of a section: a grey [label] and its [value]. A [value] that is
/// a number, a code or a unit (a phone number, «A+», «500 mg») is [ltr]: it
/// is set left to right on its own, so an Arabic page never reverses it.
/// [extra] is a second, grey value at the end of the line, always left to
/// right (the phone number of a contact).
class RecordPdfRow {
  const RecordPdfRow({
    this.label,
    required this.value,
    this.ltr = false,
    this.extra,
    this.unit,
  });

  final String? label;
  final String value;
  final bool ltr;
  final String? extra;
  final String? unit;
}

/// A block in a section, such as one medicine: its [title], a short
/// [detail] made of pieces (each piece is one run, so «500 mg» and «أقراص»
/// keep their own direction), a [badge] (حالي / سابق) and its [rows] (the
/// dose times).
class RecordPdfItem {
  const RecordPdfItem({
    required this.title,
    this.detail = const <RecordPdfRow>[],
    this.badge,
    this.badgeMuted = false,
    this.rows = const <RecordPdfRow>[],
    this.fields = const <RecordPdfRow>[],
  });

  final String title;
  final List<RecordPdfRow> detail;
  final String? badge;

  /// A grey badge (a medicine that ended) instead of the green one.
  final bool badgeMuted;
  final List<RecordPdfRow> rows;
  final List<RecordPdfRow> fields;
}

/// A section of the record: a heading, then label-value [rows] in a box,
/// or [items] as blocks, or the [empty] line.
class RecordPdfSection {
  const RecordPdfSection({
    required this.title,
    this.rows = const <RecordPdfRow>[],
    this.items = const <RecordPdfItem>[],
    this.empty,
  });

  final String title;
  final List<RecordPdfRow> rows;
  final List<RecordPdfItem> items;
  final String? empty;
}

/// Builds the selected care record locally and opens the iOS share sheet.
///
/// The page is set for reading on paper: a header with the app name and the
/// date, one heading per section, label-value lines in a light box, and a
/// footer with the page number. The fonts have no glyph for the invisible
/// direction marks the app uses on screen, so they are taken out of every
/// text; numbers keep their order by being set left to right on their own.
class RecordPdfExporter {
  static final PdfColor _ink = PdfColor.fromHex('#202734');
  static final PdfColor _slate = PdfColor.fromHex('#4E5A75');
  static final PdfColor _line = PdfColor.fromHex('#DFE2EA');
  static final PdfColor _panel = PdfColor.fromHex('#F6F7F9');
  // The app's leaf tint (AppColors.leafTint).
  static final PdfColor _leaf = PdfColor.fromHex('#E3F3EA');
  static final PdfColor _leafInk = PdfColor.fromHex('#3D6B1C');

  static const double _labelWidth = 110;

  /// The column of a dose time, wide enough for «22:00» and a little air.
  static const double _timeWidth = 40;

  /// The direction marks and isolates (U+200E, U+200F, U+202A to U+202E,
  /// U+2066 to U+2069). The PDF font draws them as boxes.
  static final RegExp _marks = RegExp(
    '[\u200E\u200F\u202A-\u202E\u2066-\u2069]',
  );

  static String plain(String text) => text.replaceAll(_marks, '').trim();

  Future<void> share({
    required String title,
    required String subtitle,
    required String appName,
    required String Function(int page, int pages) pageLabel,
    required List<RecordPdfSection> sections,
  }) async {
    final pw.Font regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    final pw.Font bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
    );
    final pw.Document document = pw.Document(title: plain(title));
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 200,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle: pw.TextStyle(
            font: regular,
            fontSize: 11,
            lineSpacing: 3,
            color: _ink,
          ),
        ),
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 32),
        header: (pw.Context context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  plain(title),
                  style: pw.TextStyle(fontSize: 9, color: _slate),
                ),
              ),
        footer: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line)),
          ),
          child: pw.Row(
            children: <pw.Widget>[
              pw.Text(
                plain(appName),
                style: pw.TextStyle(font: bold, fontSize: 9, color: _slate),
              ),
              pw.Spacer(),
              pw.Text(
                plain(pageLabel(context.pageNumber, context.pagesCount)),
                style: pw.TextStyle(fontSize: 9, color: _slate),
              ),
            ],
          ),
        ),
        build: (pw.Context context) => <pw.Widget>[
          _title(title, subtitle, appName, bold),
          pw.SizedBox(height: 20),
          for (final RecordPdfSection section in sections)
            ..._section(section, bold),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'tafaqod-care-record.pdf',
    );
  }

  pw.Widget _title(
    String title,
    String subtitle,
    String appName,
    pw.Font bold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          plain(appName),
          style: pw.TextStyle(font: bold, fontSize: 11, color: _leafInk),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          plain(title),
          style: pw.TextStyle(font: bold, fontSize: 22, color: _ink),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          plain(subtitle),
          style: pw.TextStyle(fontSize: 10, color: _slate),
        ),
      ],
    );
  }

  List<pw.Widget> _section(RecordPdfSection section, pw.Font bold) {
    final String? empty = section.empty;
    return <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.2)),
        ),
        child: pw.Text(
          plain(section.title),
          style: pw.TextStyle(font: bold, fontSize: 15),
        ),
      ),
      if (section.rows.isNotEmpty) _box(section.rows),
      for (final RecordPdfItem item in section.items) _item(item, bold),
      if (empty != null)
        pw.Text(plain(empty), style: pw.TextStyle(color: _slate)),
      pw.SizedBox(height: 22),
    ];
  }

  /// Label-value lines in a light box, with a thin line between them.
  pw.Widget _box(List<RecordPdfRow> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: <pw.Widget>[
          for (int i = 0; i < rows.length; i++)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: i == 0
                  ? null
                  : pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: _line)),
                    ),
              child: _row(rows[i]),
            ),
        ],
      ),
    );
  }

  pw.Widget _row(RecordPdfRow row) {
    final String? label = row.label;
    final String? extra = row.extra;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        if (label != null)
          pw.SizedBox(
            width: _labelWidth,
            child: pw.Text(
              plain(label),
              style: pw.TextStyle(fontSize: 10, color: _slate),
            ),
          ),
        pw.Expanded(
          child: row.unit == null
              ? _value(row.value, ltr: row.ltr)
              : pw.Row(
                  children: [
                    pw.Text(
                      plain(row.value),
                      textDirection: pw.TextDirection.ltr,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      plain(row.unit!),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
        ),
        if (extra != null)
          pw.Text(
            plain(extra),
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(fontSize: 10.5, color: _slate),
          ),
      ],
    );
  }

  /// A value on its own: left to right when it is a number or a code, and
  /// still placed at the start (the right) of its cell.
  pw.Widget _value(String value, {required bool ltr, pw.TextStyle? style}) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        plain(value),
        textDirection: ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
        style: style,
      ),
    );
  }

  /// One medicine: the name and its badge, the strength and form, and one
  /// line per dose time.
  pw.Widget _item(RecordPdfItem item, pw.Font bold) {
    final String? badge = item.badge;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  plain(item.title),
                  style: pw.TextStyle(font: bold, fontSize: 12.5),
                ),
              ),
              if (badge != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: item.badgeMuted ? _panel : _leaf,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    plain(badge),
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: item.badgeMuted ? _slate : _leafInk,
                    ),
                  ),
                ),
            ],
          ),
          if (item.detail.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 2),
            pw.Wrap(
              spacing: 6,
              children: <pw.Widget>[
                for (int i = 0; i < item.detail.length; i++) ...<pw.Widget>[
                  if (i > 0) pw.Text('·', style: pw.TextStyle(color: _slate)),
                  pw.Text(
                    plain(item.detail[i].value),
                    textDirection: item.detail[i].ltr
                        ? pw.TextDirection.ltr
                        : pw.TextDirection.rtl,
                    style: pw.TextStyle(fontSize: 10.5, color: _slate),
                  ),
                ],
              ],
            ),
          ],
          if (item.rows.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            for (final RecordPdfRow row in item.rows)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                // The time in its own column at the start (the right),
                // a dot, then the dose: «08:00 · 1 قرص». The time is set
                // left to right and pushed to the start of its column, so
                // it never touches the dose.
                child: pw.Row(
                  children: <pw.Widget>[
                    pw.Container(
                      width: _timeWidth,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        plain(row.label ?? ''),
                        textDirection: pw.TextDirection.ltr,
                        style: pw.TextStyle(font: bold, fontSize: 10.5),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                      child: pw.Text('·', style: pw.TextStyle(color: _slate)),
                    ),
                    pw.Expanded(
                      child: _value(
                        row.value,
                        ltr: row.ltr,
                        style: const pw.TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (item.fields.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            _box(item.fields),
          ],
        ],
      ),
    );
  }
}
