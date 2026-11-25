import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A contact's facts under their name, the same four the detailed mode
/// shows: who they are to the patient, their number, and whether that
/// number uses تفقُد.
class SimplifiedContactLines extends StatelessWidget {
  const SimplifiedContactLines({super.key, required this.contact});

  final EmergencyContact contact;

  static String _verified(BuildContext context, EmergencyContact contact) =>
      context.tr(
        contact.verified
            ? 'circles.contact_verified'
            : 'circles.contact_unverified',
      );

  /// The same facts as one line, for the screen reader.
  static List<String> of(BuildContext context, EmergencyContact contact) =>
      <String>[
        contact.name,
        MedicalTexts.relation(context, contact),
        MedicalTexts.phone(contact),
        _verified(context, contact),
      ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(contact.name, style: SimplifiedStyle.head(SimplifiedStyle.body)),
      Text(
        MedicalTexts.relation(context, contact),
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
      // A number reads left to right inside Arabic text.
      Text(
        MedicalTexts.phone(contact),
        textDirection: TextDirection.ltr,
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
      Text(
        _verified(context, contact),
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
    ],
  );
}

/// The simplified mode's way of writing a time: آ«6:00 ظ…ط³ط§ط،ظ‹آ».
String simplifiedTime(BuildContext context, String time) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final String minute = parts[1].padLeft(2, '0');
  final String period = context.tr(
    hour < 12 ? 'simplified_mode.am' : 'simplified_mode.pm',
  );
  return '${hour % 12 == 0 ? 12 : hour % 12}:$minute $period';
}

/// The patient's clock time at the instant [at]: آ«2:09 ظ…ط³ط§ط،ظ‹آ».
String simplifiedClockAt(BuildContext context, DateTime at) {
  final DateTime wall = PatientClockScope.of(context).wallTime(at);
  return simplifiedTime(
    context,
    '${wall.hour}:${wall.minute.toString().padLeft(2, '0')}',
  );
}

/// آ«ط§ظ„ظٹظˆظ…طŒ ط§ظ„ط¬ظ…ط¹ط© 6 ظ†ظˆظپظ…ط¨ط±آ».
String simplifiedToday(BuildContext context, DateTime now) {
  final DateTime day = PatientClockScope.of(context).today(now);
  final parts = calendarParts(context, day);
  return context.tr(
    'simplified_mode.today_date',
    args: <String>[
      context.tr('common.weekdays.${day.weekday}'),
      '${parts.day}',
      parts.month,
    ],
  );
}

/// How long until [at] (the patient's wall time) from the instant [now],
/// in the detailed mode's words: آ«ط¨ط¹ط¯ ط³ط§ط¹طھظٹظ†آ», آ«ط¨ط¹ط¯ 3 ط¯ظ‚ط§ط¦ظ‚آ», or آ«ط§ظ„ط¢ظ†آ»
/// once it came.
String simplifiedUntil(BuildContext context, DateTime at, DateTime now) {
  final DateTime wall = PatientClockScope.of(context).wallTime(now);
  final int minutes = at.difference(wall).inMinutes;
  if (minutes <= 0) return context.tr('simplified_mode.now');
  return afterDuration(context, minutes);
}
