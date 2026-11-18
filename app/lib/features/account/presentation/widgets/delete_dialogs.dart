import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_confirm_dialogs.dart';
import 'package:app/features/account/presentation/widgets/patient_choice_dialog.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:flutter/material.dart';

export 'package:app/features/account/presentation/widgets/delete_confirm_dialogs.dart';
export 'package:app/features/account/presentation/widgets/patient_choice_dialog.dart';

/// Asks the question of the delete flow that [cubit] is waiting on, and
/// gives the answer back to it. [confirm] asks the first question; a mode
/// can ask it its own way.
Future<void> answerDeletePrompt(
  BuildContext context,
  AccountCubit cubit,
  DeletePrompt prompt, {
  Future<bool?> Function(BuildContext context) confirm =
      showDeleteConfirmDialog,
}) async {
  switch (prompt) {
    case DeletePrompt.none:
      return;
    case DeletePrompt.confirm:
      final bool? agreed = await confirm(context);
      if (agreed == true) {
        await cubit.confirmDelete();
      } else {
        cubit.cancelDelete();
      }
    case DeletePrompt.patientChoice:
      final PatientChoice? choice = await showPatientChoiceDialog(context);
      if (choice == null) {
        cubit.cancelDelete();
      } else {
        await cubit.choosePatient(choice);
      }
    case DeletePrompt.lastManager:
      final bool? agreedToAll = await showLastManagerDialog(context);
      if (agreedToAll == true) {
        await cubit.confirmLastManager();
      } else {
        cubit.cancelDelete();
      }
  }
}
