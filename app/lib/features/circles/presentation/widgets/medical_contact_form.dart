import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_opening.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_buttons.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The card that adds a contact or changes one, wired to the page's cubit.
/// [savedName] is the name the contact has now, for the question asked
/// before it is deleted; it is null for a new contact.
Widget medicalContactForm(
  BuildContext context,
  MedicalFileCubit cubit,
  ContactForm form,
  String? savedName,
) {
  final String? contactId = form.contactId;
  return ContactFormCard(
    // A new key for each contact, so the text fields start from its values.
    key: ValueKey<String>(contactId ?? 'new-contact'),
    props: ContactFormProps(
      form: form,
      onRelation: cubit.relationChosen,
      onRelationOther: cubit.relationOtherChanged,
      onName: cubit.nameChanged,
      onPhone: cubit.phoneChanged,
      onSave: cubit.saveContact,
      onCancel: cubit.cancelForm,
      onDelete: contactId == null || savedName == null
          ? null
          : () => _delete(context, cubit, savedName),
      choices: _members(cubit),
      onChoose: cubit.memberChosen,
      circleId: cubit.circleId,
    ),
  );
}

/// The circle's members who are not a contact yet.
List<ContactChoice> _members(MedicalFileCubit cubit) => <ContactChoice>[
  for (final ContactChoice choice
      in cubit.state.choices ?? const <ContactChoice>[])
    if (!(cubit.state.file?.contacts ?? const <EmergencyContact>[]).any(
      (EmergencyContact contact) => contact.nationalNumber == choice.phone,
    ))
      choice,
];

Future<void> _delete(
  BuildContext context,
  MedicalFileCubit cubit,
  String name,
) async {
  final bool? agreed = await showDeleteContactDialog(context, name);
  if (agreed == true) await cubit.deleteContact();
}

/// "Delete this contact?" asked before a contact leaves the medical file and
/// the emergency card. True when the person agreed.
Future<bool?> showDeleteContactDialog(BuildContext context, String name) {
  return showAppAlert<bool>(
    context,
    title: context.tr('circles.contact_delete_title'),
    message: context.tr('circles.contact_delete_body', args: <String>[name]),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(
        label: context.tr('circles.contact_delete_no'),
        value: false,
      ),
      AppAlertAction<bool>(
        label: context.tr('circles.contact_delete_yes'),
        value: true,
        destructive: true,
      ),
    ],
  );
}

/// The card that adds an emergency contact or changes one (CIRCLE-05): the
/// relation chips, a new contact's circle members to pick from, the name,
/// the number, and the save and cancel buttons. A contact that already
/// exists also has a delete button.
///
/// The page keeps the answers in the [ContactFormProps.form]; this widget
/// only shows them, and holds the typed text while the card is open.
class ContactFormCard extends StatefulWidget {
  const ContactFormCard({super.key, required this.props});

  final ContactFormProps props;

  @override
  State<ContactFormCard> createState() => _ContactFormCardState();
}

class _ContactFormCardState extends State<ContactFormCard> {
  late final ContactFormText _typed = ContactFormText(widget.props.form);

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _pick(ContactChoice choice) {
    _typed.fillFrom(choice);
    widget.props.onChoose?.call(choice);
  }

  @override
  Widget build(BuildContext context) {
    final ContactFormProps props = widget.props;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ContactFormTitle(isNew: props.form.isNew),
          ...contactRelationChips(context, props, _typed),
          ...contactMemberChoices(context, props, onPick: _pick),
          ...contactNamePhoneFields(context, props, _typed),
          ...contactFormButtons(context, props),
        ],
      ),
    );
  }
}

/// The heading of the contact card: whether it is adding a contact or
/// changing one, and the gap under it.
class ContactFormTitle extends StatelessWidget {
  const ContactFormTitle({super.key, required this.isNew});

  final bool isNew;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Semantics(
        header: true,
        child: Text(
          context.tr(
            isNew ? 'circles.contact_new_title' : 'circles.contact_edit_title',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ],
  );
}

/// «صلة القرابة»: one chip per relation, the red line under them once the
/// person tried to save without choosing one, and with «أخرى» a field for
/// the relation in their own words.
List<Widget> contactRelationChips(
  BuildContext context,
  ContactFormProps props,
  ContactFormText typed,
) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Text(
      context.tr('circles.contact_relation'),
      style: text.titleSmall?.copyWith(color: context.tokens.textSecondary),
    ),
    const SizedBox(height: AppSpacing.sm),
    OptionChips(
      options: <ChipOption>[
        for (final String code in MedicalOptions.contactRelations)
          ChipOption(code, context.tr('medical.relation.$code')),
      ],
      isSelected: (String code) => code == props.form.relation,
      onTap: props.form.saving ? (_) {} : props.onRelation,
    ),
    if (props.form.showErrors && props.form.relation == null) ...<Widget>[
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.tr('common.field_required'),
        style: text.bodySmall?.copyWith(color: AppSemanticColors.statusError),
      ),
    ],
    if (props.form.relation == MedicalOptions.other) ...<Widget>[
      const SizedBox(height: AppSpacing.md),
      LabeledTextField(
        label: context.tr('circles.contact_relation_other'),
        helperText: context.tr('circles.contact_relation_other_hint'),
        controller: typed.relationOther,
        maxLength: MedicalOptions.contactRelationMaxLength,
        onChanged: props.onRelationOther,
        errorText: props.form.relationOtherMissing
            ? context.tr('common.field_required')
            : null,
      ),
    ],
  ];
}

/// The contact's name and number. A number already among the contacts is
/// said under it; any other refusal of the last save is a toast.
List<Widget> contactNamePhoneFields(
  BuildContext context,
  ContactFormProps props,
  ContactFormText typed,
) {
  final String? key = props.form.errorKey;
  final String? numberError = key == 'circles.duplicate_contact'
      ? context.tr(key!)
      : null;
  return <Widget>[
    const SizedBox(height: AppSpacing.lg),
    LabeledTextField(
      label: context.tr('circles.contact_name'),
      controller: typed.name,
      maxLength: MedicalOptions.contactNameMaxLength,
      onChanged: props.onName,
      errorText: props.form.showErrors && props.form.name.trim().isEmpty
          ? context.tr('common.field_required')
          : null,
    ),
    const SizedBox(height: AppSpacing.lg),
    ErrorToast(
      errorKey: numberError == null ? key : null,
      child: PhoneField(
        controller: typed.phone,
        label: context.tr('circles.contact_phone'),
        autofocus: false,
        showError: props.form.showErrors && !props.form.phoneValid,
        error: numberError,
        onChanged: (String text) =>
            props.onPhone(ArabicDigits.digitsOnly(text)),
      ),
    ),
  ];
}
