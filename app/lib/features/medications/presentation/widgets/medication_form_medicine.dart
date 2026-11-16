import 'package:app/features/medications/presentation/widgets/medication_basic_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_photo.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:flutter/material.dart';

/// The medicine itself at the top of the form: its name, strength, form and
/// photo.
class MedicationFormMedicine extends StatelessWidget {
  const MedicationFormMedicine({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    return MedicationBasicFields(
      data: state.data,
      issue: state.issue,
      onChanged: state.changed,
      photoField: MedicationPhotoField(
        circleId: state.widget.circleId,
        planId: state.widget.plan?.id,
        photo: state.photo,
        removed: state.photoRemoved,
        onChanged: state.photoChanged,
      ),
    );
  }
}
