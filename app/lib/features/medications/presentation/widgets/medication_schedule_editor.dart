import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_repeat_block.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_header.dart';
import 'package:easy_localization/easy_localization.dart';
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
