import 'dart:async';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/permissions/notification_words.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/core/widgets/forms/calendar_sync_notice.dart';
import 'package:app/core/widgets/forms/notifications_tap.dart';
import 'package:app/core/widgets/forms/permission_confirm.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/layout/toggle_row.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
                      ? AccountEndpoints.accountPhoto
                      : CircleEndpoints.patientPhoto(circle.id),
                  avatarCode: circle.patientAvatarCode,
                  size: SettingsIconTile.size,
                ),
              ),
          ],
        ),
        CalendarSyncNotice(
          circleIds: <String>[
            for (final CareCircleSummary circle in circles) circle.id,
          ],
        ),
        const CalendarSyncHint(),
      ],
    );
  }
}

/// The one explanation of what calendar sync does, shown once beneath
/// however many circles' toggles a page lists.
class CalendarSyncHint extends StatelessWidget {
  const CalendarSyncHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.sm,
        start: AppSpacing.inset,
        end: AppSpacing.inset,
      ),
      child: Text(
        context.tr('circle_overview.calendar_sync_hint'),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.tokens.textSecondary),
      ),
    );
  }
}

/// The circles in one group, a switch each: on copies that circle's doses,
/// measurement times and appointments to the phone's calendar.
class CalendarSyncCircleList extends StatelessWidget {
  const CalendarSyncCircleList({super.key, required this.circles});

  final List<CalendarSyncCircle> circles;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: <Widget>[
        for (final CalendarSyncCircle circle in circles)
          CalendarSyncCircleRow(
            key: ValueKey<String>(circle.id),
            circleId: circle.id,
            name: circle.name,
            leading: circle.leading,
          ),
      ],
    );
  }
}

/// One circle's calendar switch: on copies its doses, its measurement times
/// and its appointments to the phone's calendar, off takes them off again.
/// One switch per circle, not one per kind.
class CalendarSyncCircleRow extends StatefulWidget {
  const CalendarSyncCircleRow({
    super.key,
    required this.circleId,
    required this.name,
    this.leading,
  });

  final String circleId;

  final String name;
  final Widget? leading;

  @override
  State<CalendarSyncCircleRow> createState() => _CircleCalendarState();
}

class _CircleCalendarState extends State<CalendarSyncCircleRow>
    with CalendarSyncChoices<CalendarSyncCircleRow> {
  @override
  String get calendarCircleId => widget.circleId;

  @override
  Widget build(BuildContext context) {
    return ToggleRow(
      label: widget.name,
      leading: widget.leading,
      value: enabled ?? false,
      onChanged: (bool value) => unawaited(setChoice(value)),
    );
  }
}

/// One circle in a [CalendarSyncCircleList]: its id, the name shown, and a
/// small picture before the name (the patient's photo).
typedef CalendarSyncCircle = ({String id, String name, Widget? leading});

/// «تنبيهات الجوال» in «حسابي»: whether the phone lets the reminders
/// arrive, and the way to Settings when it does not. The calendar card
/// showed the refusal before, which buried it under another feature and
/// hid it from anyone with no circle yet.
class AccountNotificationsCard extends StatefulWidget {
  const AccountNotificationsCard({super.key});

  @override
  State<AccountNotificationsCard> createState() =>
      _AccountNotificationsCardState();
}

class _AccountNotificationsCardState extends State<AccountNotificationsCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Read it now: nothing may have scheduled a reminder yet, and the
    // state is null until something asks. Read it again on the way back
    // from Settings, where the answer is the one thing that can change.
    _refresh();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() => unawaited(GetIt.I<DoseReminders>().refreshPermission());

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SectionTitle(context.tr('account.notifications_title')),
      ValueListenableBuilder<AppPermission?>(
        valueListenable: GetIt.I<DoseReminders>().allowed,
        builder: (BuildContext context, AppPermission? allowed, Widget? _) =>
            allowed == null
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SettingsCard(
                    children: <Widget>[NotificationStateRow(allowed: allowed)],
                  ),
                  NotificationNote(allowed: allowed),
                ],
              ),
      ),
    ],
  );
}

/// What sits under the notifications row: the way out of a refusal or of
/// «Deliver Quietly», the question itself while it has never been asked,
/// or the line that says what the reminders are for.
class NotificationNote extends StatelessWidget {
  const NotificationNote({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) {
    final String? problem = notificationProblemKey(allowed);
    if (problem != null) return PermissionDeniedRow(messageKey: problem);
    return InsetText.note(context.tr('account.notifications_hint'));
  }
}

/// The notifications switch, the same shape as the calendar rows above it.
///
/// On means both answers are yes: the phone lets the reminders through and
/// the person still wants them. Off while the phone refuses leads to its
/// Settings; off while the phone allows is the person's own choice and
/// takes the planned reminders off.
class NotificationStateRow extends StatelessWidget {
  const NotificationStateRow({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: GetIt.I<DoseReminders>().enabled.on,
    builder: (BuildContext context, bool wanted, Widget? _) => ToggleRow(
      label: context.tr('account.notifications_row'),
      hint: context.tr(notificationStateKey(allowed, wanted: wanted)),
      value: allowed.usable && wanted,
      onChanged: (bool value) =>
          unawaited(tapNotifications(context, allowed, wanted: value)),
    ),
  );
}
