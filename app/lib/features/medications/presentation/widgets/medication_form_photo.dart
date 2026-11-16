import 'dart:typed_data';

import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';

/// The photo the person picked or removed, which is saved after the plan.
extension MedicationFormPhoto on MedicationFormState {
  void photoChanged(Uint8List? bytes, bool removed) => update(() {
    photo = bytes;
    photoRemoved = removed;
    photoDirty = true;
    dirty = true;
    errorKey = null;
  });
}
