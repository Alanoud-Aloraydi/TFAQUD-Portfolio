import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_card.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/presentation/simplified_speech.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
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
          listen: <SpokenPart>[
            for (final (String label, String value) in rows)
              (id: label, text: sentences(<String>[label, value])),
            if (file != null) ...<SpokenPart>[
              (
                id: _contactsPart,
                text: context.tr('simplified_mode.file.contacts'),
              ),
              for (final EmergencyContact contact in file.contacts)
                (
                  id: _ContactCard.part(contact),
                  text: sentences(_ContactCard.lines(context, contact)),
                ),
              if (state.form == null && file.canAddContact)
                (
                  id: _addPart,
                  text: context.tr('simplified_mode.file.add_contact'),
                ),
            ],
          ],
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
                      ListenTarget(
                        id: rows[index].$1,
                        radius: 8,
                        speaker: ListenSpeaker.beside,
                        child: _Row(
                          label: rows[index].$1,
                          value: rows[index].$2,
                          last: index == rows.length - 1,
                        ),
                      ),
                  ],
                ),
              ),
              ListenTarget(
                id: _contactsPart,
                radius: 8,
                child: Text(
                  context.tr('simplified_mode.file.contacts'),
                  style: SimplifiedStyle.head(SimplifiedStyle.title),
                ),
              ),
              for (final EmergencyContact contact
                  in file?.contacts ?? const <EmergencyContact>[])
                ListenTarget(
                  id: _ContactCard.part(contact),
                  speaker: ListenSpeaker.corner,
                  child: _ContactCard(contact: contact),
                ),
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
      ListenTarget(
        id: _addPart,
        radius: 32,
        child: OutlinedButton(
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
      ),
    ];
  }
}

/// The [SpokenPart.id]s of the contacts' heading and of their add button;
/// each answer's is its label.
const Object _contactsPart = #contacts;
const Object _addPart = #addContact;

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.last});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: SimplifiedStyle.gap),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: SimplifiedStyle.disabled),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                weight: AppTextTheme.medium,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: SimplifiedStyle.head(SimplifiedStyle.title)),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final EmergencyContact contact;

  /// The card's [SpokenPart.id].
  static Object part(EmergencyContact contact) =>
      (#contact, contact.name, contact.relation);

  /// What the card says: the name, then who they are to the patient.
  static List<String> lines(BuildContext context, EmergencyContact contact) =>
      <String>[contact.name, MedicalTexts.relation(context, contact)];

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      padding: const EdgeInsets.all(SimplifiedStyle.gap),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: SimplifiedStyle.accentTint,
            child: Text(
              contact.name.characters.firstOrNull ?? '',
              style: SimplifiedStyle.head(SimplifiedStyle.title),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  contact.name,
                  style: SimplifiedStyle.head(SimplifiedStyle.body),
                ),
                Text(
                  MedicalTexts.relation(context, contact),
                  style: SimplifiedStyle.text(SimplifiedStyle.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
