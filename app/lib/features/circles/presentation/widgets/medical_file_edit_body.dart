import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_sections.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_save.dart';
import 'package:app/features/circles/presentation/widgets/medical_form_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
