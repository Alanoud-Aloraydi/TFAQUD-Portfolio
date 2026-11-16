import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet_content.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The shared add sheet: a quick reading, and a creation flow for each area
/// the account may edit in [circle] (the circle's leader decides which).
/// What they save reaches the lists by itself, because the cubits follow
/// their repositories' change streams; nothing is reloaded here.
Future<void> showHomeAddSheet(
  BuildContext context, {
  required CareCircleSummary circle,
}) {
  final String circleId = circle.id;
  return showGlassSheet<void>(
    context,
    title: context.tr('add.title'),
    builder: (BuildContext sheetContext) => HomeAddSheetContent(
      circleId: circleId,
      onMedication: circle.canManageMedications
          ? () =>
                _openFrom(sheetContext, context, Routes.newMedication(circleId))
          : null,
      onMeasurement: circle.canManageMeasurements
          ? () => _openFrom(
              sheetContext,
              context,
              Routes.newMeasurement(circleId),
            )
          : null,
      onAppointment: circle.canManageAppointments
          ? () => _openFrom(
              sheetContext,
              context,
              Routes.newAppointment(circleId),
            )
          : null,
      onReading: () {
        Navigator.of(sheetContext).pop();
        unawaited(showMeasurementReadingSheet(context));
      },
    ),
  );
}

/// Closes the sheet and opens the form at [location].
void _openFrom(
  BuildContext sheetContext,
  BuildContext context,
  String location,
) {
  Navigator.of(sheetContext).pop();
  unawaited(context.push<bool>(location));
}
