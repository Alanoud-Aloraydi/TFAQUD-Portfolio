import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/allergies_section.dart';
import 'package:app/features/circles/presentation/widgets/medical_identity_fields.dart';
import 'package:app/features/circles/presentation/widgets/medical_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The fields and the save button. It is created once the file is loaded and
/// keeps the typed text, which starts from the saved values.
class MedicalFileEditForm extends StatefulWidget {
  const MedicalFileEditForm({
    super.key,
    required this.state,
    required this.savedTo,
    required this.fileRoute,
  });

  final MedicalFileEditState state;

  /// Where to go once the file is saved, when the page was opened on its way
  /// somewhere; `null` goes back to the page under this one.
  final String? savedTo;

  /// The medical file, for a save with no page under this one.
  final String fileRoute;

  @override
  State<MedicalFileEditForm> createState() => _EditFormState();
}

class _EditFormState extends State<MedicalFileEditForm> {
  late final MedicalFormFields _fields = MedicalFormFields(widget.state);

  @override
  void didUpdateWidget(MedicalFileEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The typed text of «أخرى» is cleared in the state when «أخرى» is
    // turned off or «لا توجد حساسية» is chosen; the fields follow it.
    _fields.syncWith(widget.state.form);
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MedicalFileEditBody(
    state: widget.state,
    fields: _fields,
    savedTo: widget.savedTo,
    fileRoute: widget.fileRoute,
  );
}

/// The text under a group of chips that «أخرى» asks for. [invalid] marks it
/// red once the person tried to save it empty.
class MedicalOtherField extends StatelessWidget {
  const MedicalOtherField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.invalid,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) => LabeledTextField(
    label: context.tr('circles.other_hint'),
    controller: controller,
    maxLength: MedicalOptions.otherMaxLength,
    textInputAction: TextInputAction.done,
    onChanged: onChanged,
    errorText: invalid ? context.tr('common.field_required') : null,
  );
}

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

/// Everything the edit page scrolls through, in order: who the patient is,
/// then the questions about them. A refused save is a toast, but for the
/// birth date, which is shown under its field.
List<Widget> medicalFileEditSections(
  BuildContext context, {
  required MedicalFileEditState state,
  required MedicalFileEditCubit cubit,
  required MedicalFormFields fields,
}) => <Widget>[
  MedicalNameFields(state: state, cubit: cubit, fields: fields),
  const SizedBox(height: AppSpacing.lg),
  ...medicalIdentityFields(context, state: state, cubit: cubit),
  bloodTypeSection(context, form: state.form, cubit: cubit),
  conditionsSection(
    context,
    state: state,
    cubit: cubit,
    other: fields.conditionOther,
  ),
  allergiesSection(context, state: state, cubit: cubit, fields: fields),
  ErrorToast(
    errorKey: isBirthDateError(state.errorKey) ? null : state.errorKey,
    child: const SizedBox(height: AppSpacing.sm),
  ),
];

/// «فصيلة الدم»: one chip per blood type, one of them chosen.
Widget bloodTypeSection(
  BuildContext context, {
  required MedicalForm form,
  required MedicalFileEditCubit cubit,
}) => MedicalSection(
  title: context.tr('circles.blood_type'),
  child: OptionChips(
    options: <ChipOption>[
      for (final String type in MedicalOptions.bloodTypes)
        ChipOption(type, MedicalTexts.bloodTypeLabel(type)),
    ],
    isSelected: (String code) => code == form.bloodType,
    onTap: cubit.chooseBloodType,
  ),
);

/// «الأمراض المزمنة»: the chips, «لا يوجد» and «أخرى» among them, and the
/// text «أخرى» asks for.
Widget conditionsSection(
  BuildContext context, {
  required MedicalFileEditState state,
  required MedicalFileEditCubit cubit,
  required TextEditingController other,
}) => MedicalSection(
  title: context.tr('circles.conditions'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      OptionChips(
        options: <ChipOption>[
          for (final String code in <String>[
            ...MedicalOptions.conditions,
            MedicalOptions.none,
            MedicalOptions.other,
          ])
            ChipOption(code, context.tr('medical.condition.$code')),
        ],
        isSelected: state.form.conditions.contains,
        onTap: cubit.toggleCondition,
      ),
      if (state.form.conditions.contains(MedicalOptions.other)) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        MedicalOtherField(
          controller: other,
          onChanged: cubit.conditionOtherChanged,
          invalid: state.showErrors && state.form.conditionOther.trim().isEmpty,
        ),
      ],
    ],
  ),
);
