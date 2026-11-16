import 'package:flutter/cupertino.dart';

/// The sign of what was recorded. The check is knocked out of a filled
/// green disc, so the mark itself is white: a tick that reads at a glance
/// across the card. A dose recorded as not taken gets the quiet minus.
class DoseRecordedMark extends StatelessWidget {
  const DoseRecordedMark({super.key, required this.taken, required this.color});

  final bool taken;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
    taken ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
    color: color,
  );
}
