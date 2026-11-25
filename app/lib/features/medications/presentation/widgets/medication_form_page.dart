import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_bar.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_body.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_saving.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The form as a page: its own bar over what it asks for, and a guard on
/// the way back while anything is unsaved.
class MedicationFormPage extends StatelessWidget {
  const MedicationFormPage({super.key, required this.state});

  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    final saving = context.select(
      (MedicationsCubit cubit) =>
          cubit.state.status == MedicationsStatus.saving,
    );
    return PopScope(
      canPop: !state.dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) state.confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          titleSpacing: AppSpacing.lg,
          title: MedicationFormBar(
            isEdit: state.widget.plan != null,
            saving: saving,
            onCancel: state.cancel,
            onSave: state.submit,
          ),
        ),
        body: MedicationFormBody(state: state),
      ),
    );
  }
}

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

/// The form that adds a medicine or changes one. [plan] is the medicine
/// being changed; null adds a new one.
class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key, required this.circleId, this.plan});

  final String circleId;
  final MedicationPlan? plan;

  @override
  State<MedicationForm> createState() => MedicationFormState();
}
