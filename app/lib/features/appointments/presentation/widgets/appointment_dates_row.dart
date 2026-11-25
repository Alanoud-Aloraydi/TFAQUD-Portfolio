import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_days.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_fields.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companion_chips.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_texts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The days of a booking, each its own visit with the same type, time and
/// place. The row is the main visit's day (the first), and a tap changes
/// it; «إضافة يوم» under it adds another, and a chip takes a day off while
/// another is left (the next one becomes the main). While a visit is
/// edited ([single]) the row is its one day.
class AppointmentDatesRow extends StatelessWidget {
  const AppointmentDatesRow({
    super.key,
    required this.dates,
    required this.onChanged,
    this.single = false,
  });

  /// The main day first, then the added ones, oldest first.
  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;
  final bool single;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      InsetRow(
        label: context.tr('appointments.main_day'),
        value: dates.isEmpty ? null : appointmentDate(context, dates.first),
        placeholder: context.tr('appointments.pick_day'),
        showChevron: true,
        onTap: () => unawaited(_pick(context, main: true)),
      ),
      if (!single)
        AppointmentDaysChips(
          dates: dates,
          onChanged: onChanged,
          onAdd: () => unawaited(_pick(context, main: false)),
        ),
    ],
  );

  /// The main day ([main]) or another one, from the patient's today.
  Future<void> _pick(BuildContext context, {required bool main}) async {
    final DateTime today = PatientClockScope.of(context).today();
    final DateTime? at = main ? dates.firstOrNull : dayAfterLast(dates);
    final DateTime? chosen = await showTafaqodDateSheet(
      context,
      title: context.tr(
        main ? 'appointments.main_day' : 'appointments.add_day',
      ),
      initialDate: at == null || at.isBefore(today) ? today : at,
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (chosen == null) return;
    onChanged(main ? withMainDay(dates, chosen) : withAddedDay(dates, chosen));
  }
}

/// The days of a booking under «أيام المواعيد», one chip each (a chip takes
/// its day off while another is left), then «إضافة يوم» and a line saying
/// each day is its own visit: so one day already reads as one of many.
class AppointmentDaysChips extends StatelessWidget {
  const AppointmentDaysChips({
    super.key,
    required this.dates,
    required this.onChanged,
    required this.onAdd,
  });

  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => InsetBlock(
    semanticLabel: context.tr('appointments.more_dates'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final DateTime day in dates)
              InputChip(
                label: Text(appointmentDate(context, day)),
                onDeleted: dates.length < 2
                    ? null
                    : () => onChanged(<DateTime>[
                        for (final DateTime d in dates)
                          if (d != day) d,
                      ]),
                deleteButtonTooltipMessage: context.tr(
                  'appointments.remove_date',
                ),
              ),
            ActionChip(
              avatar: const Icon(ActionIcons.plus),
              label: Text(context.tr('appointments.add_day')),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('appointments.days_note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/// «المرافقون»: the circle's people who may go with the patient, and who
/// the visit reminds.
class AppointmentCompanionsGroup extends StatelessWidget {
  const AppointmentCompanionsGroup({
    super.key,
    required this.form,
    required this.companions,
  });

  final AppointmentFormFields form;
  final AppointmentCompanionsState companions;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      header: context.tr('appointments.companion'),
      footer: companionHint(context, companions, form.companionIds),
      children: [
        AppointmentCompanionChips(
          circleId: form.widget.circleId,
          state: companions,
          chosen: form.companionIds,
          onToggle: (String id, bool selected) => form.update(() {
            selected ? form.companionIds.add(id) : form.companionIds.remove(id);
          }),
        ),
      ],
    );
  }
}

/// The note under «المرافقون»: who the visit reminds. The patient and the
/// companions [chosen]; for a patient without a phone, the companions, or
/// the circle's leader when nobody goes with them.
String companionHint(
  BuildContext context,
  AppointmentCompanionsState state,
  Set<String> chosen,
) => context.tr(
  state.patientHasPhone
      ? 'appointments.companion_hint'
      : chosen.isEmpty
      ? 'appointments.companion_hint_leader'
      : 'appointments.companion_hint_no_phone',
);

/// Where the visit is held: video or phone for a remote visit, otherwise
/// the place typed in.
class AppointmentPlaceBlock extends StatelessWidget {
  const AppointmentPlaceBlock({super.key, required this.form});

  final AppointmentFormFields form;

  @override
  Widget build(BuildContext context) {
    if (form.kind == AppointmentKind.remote) {
      return InsetBlock(
        semanticLabel: context.tr('appointments.remote_method'),
        child: GlassSegmentedControl<String>(
          segments: {
            'video': context.tr('appointments.video'),
            'phone': context.tr('appointments.phone'),
          },
          selected: form.remoteMethod,
          onChanged: (value) => form.update(() => form.remoteMethod = value),
        ),
      );
    }
    return FieldWithError(
      error: form.fieldError('appointments.place_required'),
      child: InsetTextRow(
        label: context.tr('appointments.place'),
        hint: context.tr('appointments.place_hint'),
        controller: form.place,
        maxLength: 160,
        maxLines: 3,
        onChanged: (_) => form.update(() => form.errorKey = null),
      ),
    );
  }
}
