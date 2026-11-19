import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «التاريخ» in «حسابي»: هجري or ميلادي for every date of the app on this
/// phone, with today written in the chosen one under it.
class AccountCalendarCard extends StatelessWidget {
  const AccountCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final DateCalendar chosen = CalendarScope.of(context);
    final DateTime today = PatientClockScope.of(context).today();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitle(context.tr('calendar.title')),
        SettingsCard(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GlassSegmentedControl<DateCalendar>(
                segments: <DateCalendar, String>{
                  DateCalendar.hijri: context.tr('calendar.hijri'),
                  DateCalendar.gregorian: context.tr('calendar.gregorian'),
                },
                selected: chosen,
                onChanged: AppCalendar.choose,
              ),
            ),
          ],
        ),
        InsetText.note(
          context.tr(
            'calendar.note.${chosen.name}',
            args: <String>[
              context.tr('common.weekdays.${today.weekday}'),
              calendarDate(context, today),
            ],
          ),
        ),
      ],
    );
  }
}
