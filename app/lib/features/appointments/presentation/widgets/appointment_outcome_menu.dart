import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/features/appointments/domain/appointment_outcome.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The menu of [choices] grown out of the badge at [anchor], [current]
/// ticked; the one picked, or null when the person taps outside it.
Future<AppointmentOutcome?> pickAppointmentOutcome(
  BuildContext anchor, {
  required List<AppointmentOutcome> choices,
  required AppointmentOutcome? current,
  required Widget badge,
}) => showGlassMenu<AppointmentOutcome>(
  anchorContext: anchor,
  semanticLabel: anchor.tr('appointments.outcome_menu'),
  anchorContent: badge,
  sections: <List<GlassMenuItem<AppointmentOutcome>>>[
    <GlassMenuItem<AppointmentOutcome>>[
      for (final AppointmentOutcome choice in choices)
        GlassMenuItem<AppointmentOutcome>(
          value: choice,
          label: anchor.tr(choice.labelKey),
          selected: choice == current,
        ),
    ],
  ],
);
