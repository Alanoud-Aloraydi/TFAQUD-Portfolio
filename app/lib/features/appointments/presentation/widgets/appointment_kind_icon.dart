import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/appointment_icons.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:flutter/widgets.dart';

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
  AppointmentKind.dialysis => AppIcons.drop,
  AppointmentKind.therapySession => AppointmentIcons.handHeart,
  AppointmentKind.dressing => AppointmentIcons.bandaids,
  AppointmentKind.vaccine => AppointmentIcons.syringe,
  AppointmentKind.checkup => AppIcons.heartbeat,
  AppointmentKind.dental => AppointmentIcons.tooth,
  AppointmentKind.pharmacy => AppIcons.pill,
  AppointmentKind.mental => AppointmentIcons.brain,
  AppointmentKind.speech => AppointmentIcons.userSound,
  AppointmentKind.other => AppIcons.calendar,
};
