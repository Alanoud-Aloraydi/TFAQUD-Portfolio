import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_sections.dart';
import 'package:app/features/circles/presentation/widgets/medical_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The questions of the medical file, scrolling, with «حفظ» under them that
/// stays in place.
class MedicalFileEditBody extends StatelessWidget {
  const MedicalFileEditBody({
    super.key,
    required this.state,
    required this.fields,
    required this.savedTo,
    required this.fileRoute,
  });

  final MedicalFileEditState state;
  final MedicalFormFields fields;
  final String? savedTo;
  final String fileRoute;

  @override
  Widget build(BuildContext context) {
    final MedicalFileEditCubit cubit = context.read<MedicalFileEditCubit>();
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: medicalFileEditSections(
                context,
                state: state,
                cubit: cubit,
                fields: fields,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('circles.file_save'),
          isLoading: state.saving,
          onPressed: () => saveMedicalFile(
            context,
            cubit,
            savedTo: savedTo,
            fileRoute: fileRoute,
          ),
        ),
      ],
    );
  }
}

/// Saves the medical file and, once it is saved, says so and leaves: for
/// [savedTo] when the page was opened on its way somewhere, else back to
/// the page under this one, else to the file itself.
Future<void> saveMedicalFile(
  BuildContext context,
  MedicalFileEditCubit cubit, {
  required String? savedTo,
  required String fileRoute,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final GoRouter router = GoRouter.of(context);
  final String saved = context.tr('circles.file_saved');
  if (!await cubit.save()) return;
  AppToast.showText(messenger, saved);
  if (savedTo != null) {
    router.go(savedTo);
  } else if (router.canPop()) {
    router.pop();
  } else {
    router.go(fileRoute);
  }
}
