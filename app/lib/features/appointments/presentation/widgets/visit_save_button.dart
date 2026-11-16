import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The «حفظ» of the «تعديل ورقة الزيارة» sheet, dimmed while it saves.
Widget visitSaveButton(
  BuildContext context, {
  required TextEditingController summary,
  required TextEditingController recommendations,
  required TextEditingController followUp,
}) => FilledButton(
  onPressed: context.watch<VisitCubit>().state.saving
      ? null
      : () => _save(
          context,
          summary: summary.text,
          recommendations: recommendations.text,
          followUp: followUp.text,
        ),
  child: Text(context.tr('appointments.save')),
);

/// Saves what was written, then says «تم حفظ ورقة الزيارة» and closes.
Future<void> _save(
  BuildContext context, {
  required String summary,
  required String recommendations,
  required String followUp,
}) async {
  final saved = await context.read<VisitCubit>().save(
    VisitPaperDraft(
      summary: summary,
      recommendations: recommendations,
      followUp: followUp,
    ),
  );
  if (saved && context.mounted) {
    AppToast.show(context, 'toast.visit_saved');
    Navigator.of(context).pop();
  }
}
