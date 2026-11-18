/// A cell of a table. A number or a time is [ltr]; [warn] marks a value
/// outside its target (it is also bold, so a black-and-white print shows it).
class RecordPdfCell {
  const RecordPdfCell(this.text, {this.ltr = false, this.warn = false});

  final String text;
  final bool ltr;
  final bool warn;
}
