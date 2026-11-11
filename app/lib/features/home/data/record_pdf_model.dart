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
  });

  final String? label;
  final String value;
  final bool ltr;
  final String? extra;
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

/// A cell of a table. A number or a time is [ltr]; [warn] marks a value
/// outside its target (it is also bold, so a black-and-white print shows it).
class RecordPdfCell {
  const RecordPdfCell(this.text, {this.ltr = false, this.warn = false});

  final String text;
  final bool ltr;
  final bool warn;
}

/// A table with a [title], its column [headers] and [rows]. [flex] sizes the
/// columns against each other.
class RecordPdfTable {
  const RecordPdfTable({
    required this.title,
    required this.headers,
    required this.flex,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<int> flex;
  final List<List<RecordPdfCell>> rows;
}

/// A section of the record: a heading, then label-value [rows] in a box,
/// [tables], [items] as blocks, or the [empty] line.
class RecordPdfSection {
  const RecordPdfSection({
    required this.title,
    this.rows = const <RecordPdfRow>[],
    this.tables = const <RecordPdfTable>[],
    this.items = const <RecordPdfItem>[],
    this.empty,
  });

  final String title;
  final List<RecordPdfRow> rows;
  final List<RecordPdfTable> tables;
  final List<RecordPdfItem> items;
  final String? empty;
}

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
