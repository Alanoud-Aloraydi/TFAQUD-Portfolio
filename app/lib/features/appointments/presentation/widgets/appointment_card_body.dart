import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// When and where an appointment is, and who goes with the patient.
class AppointmentCardBody extends StatelessWidget {
  const AppointmentCardBody({
    super.key,
    required this.value,
    required this.circleId,
  });

  final CareAppointment value;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final bool remote = value.kind == AppointmentKind.remote;
    return PlanInfoBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${appointmentDate(context, value.scheduledOn)} · '
            '${clockText(value.time)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            remote
                ? context.tr('appointments.${value.remoteMethod}')
                : value.place ?? '',
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final AppointmentCompanion companion in value.companions)
                PersonPhoto(
                  name: companion.name,
                  photoPath: ApiEndpoints.memberPhoto(circleId, companion.id),
                  avatarCode: companion.avatarCode,
                  size: AppSizes.iconSmall,
                ),
              Text(appointmentCompanionLine(context, value)),
            ],
          ),
        ],
      ),
    );
  }
}
