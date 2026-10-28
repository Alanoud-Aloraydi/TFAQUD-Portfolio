import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String formatMedicationNumber(double value) =>
    value.toString().replaceFirst(RegExp(r'\.0$'), '');

String formatMedicationDate(BuildContext context, DateTime date) =>
    '${date.day} ${context.tr('circles.months.${date.month}')} ${date.year}';

String formatMedicationTime(BuildContext context, String value) {
  final parts = value.split(':');
  final hour24 = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final period = context.tr(hour24 < 12 ? 'common.am' : 'common.pm');
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}
