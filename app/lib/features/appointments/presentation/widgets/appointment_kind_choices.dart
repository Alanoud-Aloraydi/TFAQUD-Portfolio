import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/appointment_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The visit's kind as chips, one row per [AppointmentKindGroup] with its
/// heading, and «أخرى» last on its own.
class AppointmentKindChoices extends StatelessWidget {
  const AppointmentKindChoices({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppointmentKind selected;
  final ValueChanged<AppointmentKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final TextStyle? heading = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AppointmentKindGroup group
            in AppointmentKindGroup.values) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              context.tr('appointments.kind_groups.${group.name}'),
              style: heading,
            ),
          ),
          _chips(context, group.kinds),
        ],
        const SizedBox(height: AppSpacing.md),
        _chips(context, const <AppointmentKind>[AppointmentKind.other]),
      ],
    );
  }

  Widget _chips(BuildContext context, List<AppointmentKind> kinds) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: <Widget>[
      for (final AppointmentKind kind in kinds)
        ChoiceChip(
          label: Text(context.tr('appointments.kinds.${kind.name}')),
          selected: selected == kind,
          onSelected: (_) => onSelected(kind),
        ),
    ],
  );
}

/// The icon of each kind of visit, wherever one visit shows (its card in
/// «الخطة» and «السجل», its row in «اليوم», the simplified mode's tile):
/// what the visit is for, at a glance. «أخرى» keeps the calendar.
IconData appointmentKindIcon(AppointmentKind kind) => switch (kind) {
  AppointmentKind.followUp => AppointmentIcons.stethoscope,
  AppointmentKind.newVisit => AppointmentIcons.clipboardText,
  AppointmentKind.remote => AppointmentIcons.videoCamera,
  AppointmentKind.emergency => AppointmentIcons.ambulance,
  AppointmentKind.test => AppointmentIcons.testTube,
  AppointmentKind.imaging => AppointmentIcons.scan,
  AppointmentKind.eyeExam => AppointmentIcons.eye,
  AppointmentKind.hearingTest => AppointmentIcons.ear,
  AppointmentKind.surgery => AppointmentIcons.hospital,
  AppointmentKind.physio => AppointmentIcons.personSimpleWalk,
  AppointmentKind.dialysis => CareIcons.drop,
  AppointmentKind.therapySession => AppointmentIcons.handHeart,
  AppointmentKind.dressing => AppointmentIcons.bandaids,
  AppointmentKind.vaccine => AppointmentIcons.syringe,
  AppointmentKind.checkup => CareIcons.heartbeat,
  AppointmentKind.dental => AppointmentIcons.tooth,
  AppointmentKind.pharmacy => CareIcons.pill,
  AppointmentKind.mental => AppointmentIcons.brain,
  AppointmentKind.speech => AppointmentIcons.userSound,
  AppointmentKind.other => ScheduleIcons.calendar,
};
