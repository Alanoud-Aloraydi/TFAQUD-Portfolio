import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_dates_row.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_group.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_lead_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The appointment form's groups, one under the other.
class AppointmentFormBody extends StatelessWidget {
  const AppointmentFormBody({
    super.key,
    required this.form,
    required this.companions,
  });

  final AppointmentFormFields form;
  final AppointmentCompanionsState companions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppointmentKindGroup(form: form),
        const SizedBox(height: AppSpacing.xl),
        AppointmentTimePlaceGroup(form: form),
        const SizedBox(height: AppSpacing.xl),
        AppointmentCompanionsGroup(form: form, companions: companions),
      ],
    );
  }
}

/// «الوقت والمكان»: the visit days, the time, how early to remind, and the
/// place or the way a remote visit is held.
class AppointmentTimePlaceGroup extends StatelessWidget {
  const AppointmentTimePlaceGroup({super.key, required this.form});

  final AppointmentFormFields form;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('appointments.time_place_group'),
      children: [
        FieldWithError(
          error: form.fieldError('appointments.days_required'),
          child: AppointmentDatesRow(
            dates: form.days,
            single: form.widget.appointmentId != null,
            onChanged: (value) => form.update(() => form.days = value),
          ),
        ),
        FieldWithError(
          error: form.fieldError('appointments.time_in_past'),
          child: InsetRow(
            label: context.tr('appointments.time'),
            value: timeOfDayText(form.time),
            showChevron: true,
            onTap: () async {
              final selected = await showTafaqodTimeSheet(
                context,
                title: context.tr('appointments.time'),
                initialTime: form.time,
              );
              if (selected != null && form.mounted) {
                form.update(() {
                  form.time = selected;
                  form.errorKey = null;
                });
              }
            },
          ),
        ),
        AppointmentLeadRow(
          minutes: form.lead,
          time: form.time,
          onChanged: (int value) => form.update(() => form.lead = value),
        ),
        AppointmentPlaceBlock(form: form),
      ],
    );
  }
}
