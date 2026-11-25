import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_interval_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One schedule row inside the medicine's grouped list.
class MedicationScheduleEditor extends StatelessWidget {
  const MedicationScheduleEditor({
    super.key,
    required this.index,
    required this.data,
    required this.units,
    required this.onChanged,
    this.onRemove,
    this.issue,
    this.startsOn,
  });

  final int index;
  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final MedicationFormIssue? issue;

  /// The day the treatment starts, where «كل كم يوم» counts from.
  final DateTime? startsOn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MedicationScheduleHeader(index: index, onRemove: onRemove),
        MedicationScheduleTimeRow(data: data, onChanged: onChanged),
        MedicationDoseRow(
          data: data,
          units: units,
          issue: issue,
          onChanged: onChanged,
        ),
        // The days have a focus node, so a missing day can be scrolled to.
        Focus(
          focusNode: data.weekdaysFocus,
          child: MedicationRepeatBlock(
            data: data,
            issue: issue,
            startsOn: startsOn,
            onChanged: onChanged,
          ),
        ),
        InsetTextRow(
          label: context.tr('medications.dose_note'),
          hint: context.tr('medications.dose_note_hint'),
          controller: data.instructionsController,
          maxLength: 250,
          maxLines: 2,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

/// Saving the medicine's photo, once the plan it belongs to has an id. The
/// form closes on «تم» whether a photo was picked or not; only a photo that
/// could not be stored keeps it open, with its own message.
extension MedicationPhotoSaving on MedicationFormState {
  Future<void> savePhoto(String planId) async {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final path = MedicationEndpoints.medicationPhoto(widget.circleId, planId);
    try {
      if (photoDirty) {
        if (photoRemoved) {
          await repository.remove(path);
        } else if (photo != null) {
          await repository.save(path, photo!);
        }
      }
    } catch (_) {
      if (mounted) update(() => errorKey = 'photos.save_failed');
      return;
    }
    if (!mounted) return;
    dirty = false;
    AppToast.show(context, 'toast.medication_saved');
    context.pop(true);
  }
}

/// «أسبوعي | كل كم يوم» on the app's glass segmented control, and under it
/// the weekdays, or the number of days on a ruler right here (not in a
/// sheet). Apple's guidance for a segmented control is this case: two
/// closely related views of one choice, short labels, segments of equal
/// width.
class MedicationRepeatBlock extends StatelessWidget {
  const MedicationRepeatBlock({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
    this.startsOn,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;
  final DateTime? startsOn;

  @override
  Widget build(BuildContext context) {
    final bool interval = data.repeat == ScheduleRepeat.interval;
    return InsetBlock(
      semanticLabel: context.tr('medications.repeat'),
      errorText: issue?.field == MedicationFormField.weekdays
          ? context.tr('medications.weekday_required')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSegmentedControl<ScheduleRepeat>(
            segments: <ScheduleRepeat, String>{
              ScheduleRepeat.weekly: context.tr('medications.repeat_weekly'),
              ScheduleRepeat.interval: context.tr(
                'medications.repeat_interval',
              ),
            },
            selected: data.repeat,
            onChanged: (ScheduleRepeat repeat) {
              data.repeat = repeat;
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (interval)
            MedicationIntervalPicker(
              data: data,
              startsOn: startsOn,
              onChanged: onChanged,
            )
          else
            MedicationWeekdaysField(data: data, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// The days of the week the dose is taken on.
class MedicationWeekdaysField extends StatelessWidget {
  const MedicationWeekdaysField({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => WeekdaySelector(
    selected: data.weekdays,
    onChanged: (Set<int> days) {
      data.weekdays
        ..clear()
        ..addAll(days);
      onChanged();
    },
  );
}

/// «جدول 1» over the row, with the button that removes it. The button is
/// absent while the medicine has one schedule left.
class MedicationScheduleHeader extends StatelessWidget {
  const MedicationScheduleHeader({
    super.key,
    required this.index,
    this.onRemove,
  });

  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? remove = onRemove;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(
                'medications.schedule_number',
                args: [(index + 1).toString()],
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (remove != null)
            IconButton(
              tooltip: context.tr('medications.remove_schedule'),
              onPressed: remove,
              color: AppSemanticColors.statusError,
              icon: const Icon(CupertinoIcons.delete),
            ),
        ],
      ),
    );
  }
}

/// The time of day the dose is taken, opened as the app's time sheet.
class MedicationScheduleTimeRow extends StatelessWidget {
  const MedicationScheduleTimeRow({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetRow(
      label: context.tr('medications.time'),
      value: clockText(scheduleTimeCode(data.time)),
      onTap: () => _selectTime(context),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? selected = await showTafaqodTimeSheet(
      context,
      initialTime: data.time,
      title: context.tr('medications.select_time'),
    );
    if (selected == null) return;
    data.time = selected;
    onChanged();
  }
}

/// A time of day as the API writes it, «HH:mm».
String scheduleTimeCode(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
