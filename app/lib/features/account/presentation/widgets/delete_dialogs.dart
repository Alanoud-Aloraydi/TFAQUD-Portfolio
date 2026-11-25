import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/delete_confirm_dialogs.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:app/features/account/presentation/widgets/delete_confirm_dialogs.dart';

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

/// The account is the patient of a circle: delete it with the account, or keep
/// it. Null when the person stopped.
Future<PatientChoice?> showPatientChoiceDialog(BuildContext context) {
  return showAppAlert<PatientChoice>(
    context,
    title: context.tr('account.patient_choice_title'),
    message: context.tr('account.patient_choice_body'),
    actions: <AppAlertAction<PatientChoice>>[
      AppAlertAction<PatientChoice>(
        label: context.tr('account.patient_choice_keep'),
        value: PatientChoice.keep,
        primary: true,
      ),
      AppAlertAction<PatientChoice>(
        label: context.tr('account.patient_choice_delete'),
        value: PatientChoice.delete,
        destructive: true,
      ),
      AppAlertAction<PatientChoice>(label: context.tr('common.cancel')),
    ],
  );
}
