import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/pickers/minutes_sheet_body.dart';
import 'package:flutter/material.dart';

/// A length of time chosen on the ruler of «ذكّرني لاحقًا»: 5 minutes a
/// mark from [min] to [max], a long mark every half hour and the hours
/// written under them. Above it, [headline] says the length («بعد ساعة»,
/// «قبل ساعة») and [subline] what it means («الساعة 9:00 ص»). Returns the
/// minutes, or null when the sheet is closed.
Future<int?> showMinutesSheet(
  BuildContext context, {
  required String title,
  required int minutes,
  required String Function(int minutes) headline,
  String Function(int minutes)? subline,
  int min = 5,
  int max = 360,
}) => showGlassSheet<int>(
  context,
  title: title,
  builder: (_) => MinutesSheetBody(
    label: title,
    minutes: minutes.clamp(min, max),
    headline: headline,
    subline: subline,
    min: min,
    max: max,
  ),
);
