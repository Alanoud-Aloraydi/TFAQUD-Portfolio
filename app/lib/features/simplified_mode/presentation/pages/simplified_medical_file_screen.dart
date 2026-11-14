import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_medical_file_contact_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_medical_file_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الملف الطبي» in the simplified mode: the patient's answers in big rows
/// and the people to call. «تعديل» opens the detailed mode's edit page
/// inside the simplified mode, and «حفظ» or «رجوع» there lands here again.
class SimplifiedMedicalFileScreen extends StatelessWidget {
  const SimplifiedMedicalFileScreen({super.key, required this.circleId});

  final String circleId;

  Future<void> _edit(BuildContext context, MedicalFile file) async {
    final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
    await context.push<void>(
      Routes.simplifiedMedicalFileEdit(circleId),
      extra: file,
    );
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicalFileCubit, MedicalFileState>(
      listenWhen: (before, after) => after.sessionEnded && !before.sessionEnded,
      listener: (context, state) => context.go(Routes.auth),
      builder: (context, state) {
        final MedicalFile? file = state.file;
        final List<(String, String)> rows = file == null
            ? const <(String, String)>[]
            : <(String, String)>[
                (
                  context.tr('simplified_mode.file.name'),
                  file.patient.fullName,
                ),
                (
                  context.tr('simplified_mode.file.birth_date'),
                  formatBirthDate(context, file.patient.birthDate),
                ),
                (
                  context.tr('simplified_mode.file.blood_type'),
                  MedicalTexts.bloodType(context, file.profile.bloodType),
                ),
                (
                  context.tr('simplified_mode.file.allergies'),
                  MedicalTexts.allergies(context, file.profile.allergies),
                ),
                (
                  context.tr('simplified_mode.file.conditions'),
                  MedicalTexts.conditions(context, file.profile.conditions),
                ),
                (context.tr('simplified_mode.file.city'), file.patient.city),
              ];
        return SimplifiedPage(
          title: context.tr('simplified_mode.file.title'),
          titleTrailing: file == null
              ? null
              : FilledButton(
                  onPressed: () => _edit(context, file),
                  style: FilledButton.styleFrom(
                    backgroundColor: SimplifiedStyle.accentTint,
                    foregroundColor: SimplifiedStyle.ink,
                    minimumSize: const Size(0, SimplifiedStyle.touch),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: Text(
                    context.tr('simplified_mode.file.edit'),
                    style: SimplifiedStyle.head(SimplifiedStyle.caption),
                  ),
                ),
          children: switch (state.status) {
            MedicalFileStatus.loading => const <Widget>[
              Center(child: CircularProgressIndicator()),
            ],
            MedicalFileStatus.failure => <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                style: SimplifiedStyle.text(
                  SimplifiedStyle.body,
                  color: SimplifiedStyle.ink,
                ),
              ),
              SimplifiedButton(
                label: context.tr('simplified_mode.try_again'),
                onPressed: context.read<MedicalFileCubit>().load,
              ),
            ],
            MedicalFileStatus.ready => <Widget>[
              SimplifiedCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: SimplifiedStyle.pad,
                  vertical: 4,
                ),
                child: Column(
                  children: <Widget>[
                    for (int index = 0; index < rows.length; index++)
                      SimplifiedMedicalFileRow(
                        label: rows[index].$1,
                        value: rows[index].$2,
                        last: index == rows.length - 1,
                      ),
                  ],
                ),
              ),
              Text(
                context.tr('simplified_mode.file.contacts'),
                style: SimplifiedStyle.head(SimplifiedStyle.title),
              ),
              for (final EmergencyContact contact
                  in file?.contacts ?? const <EmergencyContact>[])
                SimplifiedMedicalFileContactCard(contact: contact),
              ..._addContact(context, state, file),
            ],
          },
        );
      },
    );
  }

  List<Widget> _addContact(
    BuildContext context,
    MedicalFileState state,
    MedicalFile? file,
  ) {
    final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
    final ContactForm? form = state.form;
    if (form != null && form.isNew) {
      return <Widget>[
        SimplifiedDetailScale(
          child: ContactFormCard(
            key: const ValueKey<String>('new-contact'),
            form: form,
            onRelation: cubit.relationChosen,
            onName: cubit.nameChanged,
            onPhone: cubit.phoneChanged,
            onSave: cubit.saveContact,
            onCancel: cubit.cancelForm,
          ),
        ),
      ];
    }
    if (form != null || file == null || !file.canAddContact) {
      return const <Widget>[];
    }
    return <Widget>[
      OutlinedButton(
        onPressed: cubit.startAdd,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          shape: const StadiumBorder(),
          side: const BorderSide(color: SimplifiedStyle.control, width: 1.5),
          foregroundColor: SimplifiedStyle.ink,
        ),
        child: Text(
          context.tr('simplified_mode.file.add_contact'),
          style: SimplifiedStyle.label(SimplifiedStyle.body),
        ),
      ),
    ];
  }
}
