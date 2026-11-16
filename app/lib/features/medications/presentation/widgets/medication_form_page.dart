import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_bar.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_body.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_discard.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_saving.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
