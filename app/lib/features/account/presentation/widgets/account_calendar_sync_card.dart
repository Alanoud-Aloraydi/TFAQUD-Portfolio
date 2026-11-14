import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_circle_list.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_hint.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_section.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «مزامنة مع تقويم الجهاز» the way iOS Settings lays out a list of
/// switches: one switch per circle, with its patient's photo, and one
/// shared explanation below. On, the circle's doses, measurement times and
/// appointments all go to the phone's calendar.
class AccountCalendarSyncCard extends StatelessWidget {
  const AccountCalendarSyncCard({super.key, required this.circles});

  final List<CareCircleSummary> circles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.tr('circle_overview.calendar_sync_title')),
        CalendarSyncCircleList(
          circles: <CalendarSyncCircle>[
            for (final CareCircleSummary circle in circles)
              (
                id: circle.id,
                name: circle.name,
                leading: PersonPhoto(
                  name: circle.patientName ?? circle.name,
                  // The patient with their own account has one photo:
                  // the account's.
                  photoPath: circle.isPatient
                      ? ApiEndpoints.accountPhoto
                      : ApiEndpoints.patientPhoto(circle.id),
                  avatarCode: circle.patientAvatarCode,
                  size: SettingsIconTile.size,
                ),
              ),
          ],
        ),
        const CalendarSyncHint(),
      ],
    );
  }
}
