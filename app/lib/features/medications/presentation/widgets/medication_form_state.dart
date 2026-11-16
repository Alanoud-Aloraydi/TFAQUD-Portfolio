import 'dart:typed_data';

import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/widgets/medication_form.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_page.dart';
import 'package:flutter/material.dart';

/// What the form holds while it is open: the values typed, what the server
/// refused, the photo picked, and whether anything changed at all. Saving
/// it lives in `MedicationFormSaving`, leaving it in
/// `MedicationFormDiscard`, and what it draws in [MedicationFormPage].
class MedicationFormState extends State<MedicationForm> {
  /// Made on the first build, where the patient's today can be read.
  late final MedicationFormData data = MedicationFormData(
    widget.plan,
    today: PatientClockScope.of(context).today(),
  );

  String? errorKey;
  MedicationFormIssue? issue;
  bool dirty = false;
  bool medicalFieldsDirty = false;
  bool photoDirty = false;
  Uint8List? photo;
  bool photoRemoved = false;
  String? savedPlanId;

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }

  /// Redraws the form after [change]. The parts of the form that live
  /// beside this class — saving it, its photo — go through here, since
  /// setState belongs to the state itself.
  void update(VoidCallback change) => setState(change);

  /// Anything the person typed or picked: the form may now be saved, and
  /// leaving it asks first.
  void changed() => setState(() {
    dirty = true;
    medicalFieldsDirty = true;
    errorKey = null;
    issue = null;
  });

  @override
  Widget build(BuildContext context) => MedicationFormPage(state: this);
}
