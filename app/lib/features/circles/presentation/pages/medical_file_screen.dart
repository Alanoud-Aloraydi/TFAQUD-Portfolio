import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/back_link.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/contact_dialogs.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_card.dart';
import 'package:app/features/circles/presentation/widgets/contact_tile.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The medical file of a circle (CIRCLE-05): the patient's basic data and
/// health answers, and the emergency contacts, which are added, changed and
/// removed on this page. The pencil "تعديل" opens the edit page of the rest.
/// Needs a [MedicalFileCubit] above it.
class MedicalFileScreen extends StatelessWidget {
  const MedicalFileScreen({super.key, required this.circleId});

  final String circleId;

  Future<void> _edit(BuildContext context, MedicalFileCubit cubit) async {
    final bool? saved = await context.push<bool>(
      Routes.medicalFileEdit(circleId),
    );
    if (saved == true && !cubit.isClosed) cubit.load();
  }

  Future<void> _delete(
    BuildContext context,
    MedicalFileCubit cubit,
    String name,
  ) async {
    final bool? agreed = await showDeleteContactDialog(context, name);
    if (agreed == true) await cubit.deleteContact();
  }

  @override
  Widget build(BuildContext context) {
    final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MedicalFileCubit, MedicalFileState>(
          listenWhen: (MedicalFileState before, MedicalFileState after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (BuildContext context, MedicalFileState state) =>
              context.go(Routes.auth),
          builder: (BuildContext context, MedicalFileState state) {
            final MedicalFile? file = state.file;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BackLink(
                    onPressed: context.canPop()
                        ? () => context.pop()
                        : () => context.go(Routes.circle),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            context.tr('circles.file_title'),
                            style: text.headlineMedium,
                          ),
                        ),
                      ),
                      if (file != null)
                        ActionChip(
                          avatar: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.brand,
                          ),
                          label: Text(context.tr('circles.file_edit')),
                          backgroundColor: AppColors.brandTint,
                          side: BorderSide.none,
                          onPressed: () => _edit(context, cubit),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _body(context, cubit, state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MedicalFileCubit cubit,
    MedicalFileState state,
  ) {
    final MedicalFile? file = state.file;
    switch (state.status) {
      case MedicalFileStatus.loading:
        return const LoadingWidget();
      case MedicalFileStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        );
      case MedicalFileStatus.ready:
        return _ready(context, cubit, state, file!);
    }
  }

  Widget _ready(
    BuildContext context,
    MedicalFileCubit cubit,
    MedicalFileState state,
    MedicalFile file,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final ContactForm? form = state.form;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        SettingsCard(
          children: <Widget>[
            InfoRow(
              label: context.tr('circles.name'),
              value: file.patient.fullName,
            ),
            InfoRow(
              label: context.tr('circles.birth_date'),
              value: formatBirthDate(context, file.patient.birthDate),
            ),
            InfoRow(
              label: context.tr('circles.blood_type'),
              value: MedicalTexts.bloodType(context, file.profile.bloodType),
            ),
            InfoRow(
              label: context.tr('circles.allergies_title'),
              value: MedicalTexts.allergies(context, file.profile.allergies),
            ),
            InfoRow(
              label: context.tr('circles.conditions'),
              value: MedicalTexts.conditions(context, file.profile.conditions),
            ),
            InfoRow(
              label: context.tr('circles.city'),
              value: file.patient.city,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            context.tr('circles.file_contacts_title'),
            style: text.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        if (file.contacts.isEmpty && form == null)
          Text(
            context.tr('circles.file_contacts_empty'),
            style: text.bodyMedium?.copyWith(color: AppColors.ink2),
          ),
        for (final EmergencyContact contact in file.contacts) ...<Widget>[
          if (form != null && form.contactId == contact.id)
            _form(context, cubit, form, contact.name)
          else
            ContactTile(
              contact: contact,
              // One form is open at a time.
              onEdit: form == null ? () => cubit.startEdit(contact.id) : null,
            ),
          const SizedBox(height: 12),
        ],
        if (form != null && form.isNew) _form(context, cubit, form, null),
        if (form == null && file.canAddContact)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: cubit.startAdd,
              icon: const Icon(Icons.add),
              label: Text(context.tr('circles.contact_add')),
            ),
          ),
        if (form == null && !file.canAddContact)
          Text(
            context.tr('circles.contact_max'),
            style: text.bodyMedium?.copyWith(color: AppColors.ink2),
          ),
      ],
    );
  }

  /// [savedName] is the name the contact has now, for the question before it
  /// is deleted; it is null for a new contact.
  Widget _form(
    BuildContext context,
    MedicalFileCubit cubit,
    ContactForm form,
    String? savedName,
  ) {
    final String? contactId = form.contactId;
    return ContactFormCard(
      // A new key for each contact, so the text fields start from its values.
      key: ValueKey<String>(contactId ?? 'new-contact'),
      form: form,
      onRelation: cubit.relationChosen,
      onName: cubit.nameChanged,
      onPhone: cubit.phoneChanged,
      onSave: cubit.saveContact,
      onCancel: cubit.cancelForm,
      onDelete: contactId == null || savedName == null
          ? null
          : () => _delete(context, cubit, savedName),
    );
  }
}
