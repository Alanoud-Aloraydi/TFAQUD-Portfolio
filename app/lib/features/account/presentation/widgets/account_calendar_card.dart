import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/account/presentation/widgets/account_photo_button.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
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

/// The top of «حسابي»: the account's photo, with the full name and the phone
/// number under it.
class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    required this.account,
    required this.onPhotoSaved,
    super.key,
  });

  final AccountSummary account;

  /// Called once a new photo is saved, so the page reads the account again.
  final VoidCallback onPhotoSaved;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String shown = account.displayName.isNotEmpty
        ? account.displayName
        : account.fullName;
    return Column(
      children: <Widget>[
        AccountPhotoButton(
          name: shown,
          avatarCode: account.avatarCode,
          onSaved: onPhotoSaved,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(account.fullName, style: text.titleLarge),
        Text(
          SaudiMobile.display(account.phoneNumber),
          textDirection: TextDirection.ltr,
          style: text.bodySmall?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
