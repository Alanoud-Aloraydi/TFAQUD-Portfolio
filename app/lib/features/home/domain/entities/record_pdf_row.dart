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
