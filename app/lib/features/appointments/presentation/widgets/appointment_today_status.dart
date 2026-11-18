import 'package:app/core/widgets/status/status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The badge of a «اليوم» appointment: waiting once its time has come,
/// else upcoming.
Widget appointmentTodayStatus(BuildContext context, {required bool waiting}) {
  return StatusBadge(
    text: context.tr(
      waiting
          ? 'today_dashboard.status.appointment_waiting'
          : 'today_dashboard.status.upcoming',
    ),
    tone: waiting ? StatusTone.attention : StatusTone.info,
  );
}
