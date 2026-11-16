import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

/// Leaving the form: nothing typed closes it, anything typed asks first.
extension MedicationFormDiscard on MedicationFormState {
  void cancel() {
    if (dirty) {
      confirmDiscard();
    } else {
      context.pop();
    }
  }

  Future<void> confirmDiscard() async {
    final discard = await showAppAlert<bool>(
      context,
      title: context.tr('medications.discard_title'),
      message: context.tr('medications.discard_message'),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('medications.discard_confirm'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (discard == true && mounted) {
      dirty = false;
      context.pop();
    }
  }
}
