import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The card that adds an emergency contact or changes one (CIRCLE-05): the
/// relation chips, a new contact's circle members to pick from (their
/// name and number fill the fields), the name, the number, and the save and
/// cancel buttons. A contact that already exists also has a delete button.
///
/// The page keeps the answers in a [ContactForm]; this widget only shows them.
/// The text fields start from the form when the card opens, so the page gives
/// the card a key of its own for each contact.
class ContactFormCard extends StatefulWidget {
  const ContactFormCard({
    super.key,
    required this.form,
    required this.onRelation,
    required this.onName,
    required this.onPhone,
    required this.onSave,
    required this.onCancel,
    this.onDelete,
    this.choices = const <ContactChoice>[],
    this.onChoose,
    this.circleId = '',
  });

  final ContactForm form;
  final ValueChanged<String> onRelation;
  final ValueChanged<String> onName;

  /// Receives the digits of the number, already written 0-9.
  final ValueChanged<String> onPhone;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  /// Null for a new contact.
  final VoidCallback? onDelete;

  /// Circle members a new contact can be picked from.
  final List<ContactChoice> choices;
  final ValueChanged<ContactChoice>? onChoose;

  /// For a member's photo.
  final String circleId;

  @override
  State<ContactFormCard> createState() => _ContactFormCardState();
}

class _ContactFormCardState extends State<ContactFormCard> {
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.form.name);
    _phone = TextEditingController(text: SaudiMobile.group(widget.form.phone));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Puts a member's name and number in the fields and the form.
  void _choose(ContactChoice choice) {
    _name.text = choice.name;
    _phone.text = SaudiMobile.group(choice.phone);
    widget.onChoose?.call(choice);
  }

  @override
  Widget build(BuildContext context) {
    final ContactForm form = widget.form;
    final TextTheme text = Theme.of(context).textTheme;
    final String requiredText = context.tr('common.field_required');
    final bool phoneInvalid = form.showErrors && !form.phoneValid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              context.tr(
                form.isNew
                    ? 'circles.contact_new_title'
                    : 'circles.contact_edit_title',
              ),
              style: text.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('circles.contact_relation'),
            style: text.titleSmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OptionChips(
            options: <ChipOption>[
              for (final String code in MedicalOptions.contactRelations)
                ChipOption(code, context.tr('medical.relation.$code')),
            ],
            isSelected: (String code) => code == form.relation,
            onTap: form.saving ? (_) {} : widget.onRelation,
          ),
          if (form.showErrors && form.relation == null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              requiredText,
              style: text.bodySmall?.copyWith(
                color: AppSemanticColors.statusError,
              ),
            ),
          ],
          if (form.isNew && widget.choices.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('circles.contact_from_members'),
              style: text.titleSmall?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final ContactChoice choice in widget.choices)
                  _MemberChip(
                    choice: choice,
                    circleId: widget.circleId,
                    selected:
                        form.phone == choice.phone && form.name == choice.name,
                    onTap: form.saving ? null : () => _choose(choice),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          LabeledTextField(
            label: context.tr('circles.contact_name'),
            controller: _name,
            maxLength: MedicalOptions.contactNameMaxLength,
            onChanged: widget.onName,
            errorText: form.showErrors && form.name.trim().isEmpty
                ? requiredText
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          PhoneField(
            controller: _phone,
            label: context.tr('circles.contact_phone'),
            autofocus: false,
            showError: phoneInvalid,
            onChanged: (String typed) =>
                widget.onPhone(ArabicDigits.digitsOnly(typed)),
          ),
          if (form.errorKey != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            InlineError(messageKey: form.errorKey!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: PillButton(
                  label: context.tr('circles.contact_save'),
                  isLoading: form.saving,
                  onPressed: widget.onSave,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: form.saving ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppSemanticColors.textPrimary,
                    side: const BorderSide(
                      color: AppSemanticColors.borderControlBase,
                    ),
                  ),
                  child: Text(context.tr('common.cancel')),
                ),
              ),
            ],
          ),
          if (widget.onDelete != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: form.saving ? null : widget.onDelete,
                icon: const Icon(AppIcons.trash, size: AppSizes.iconSmall),
                label: Text(context.tr('circles.contact_delete')),
                // Deleting is a destructive action: the error red. No start
                // padding, so the trash sits on the card's content edge.
                style: TextButton.styleFrom(
                  foregroundColor: AppSemanticColors.statusError,
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One circle member to pick: their picture and name in a pill, marked when
/// the form holds their name and number.
class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.choice,
    required this.circleId,
    required this.selected,
    this.onTap,
  });

  final ContactChoice choice;
  final String circleId;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected
          ? AppSemanticColors.selectedSurface
          : AppSemanticColors.surfaceContent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppSemanticColors.actionPrimary
              : AppSemanticColors.borderSubtle,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.capsule),
                  child: PersonPhoto(
                    name: choice.name,
                    photoPath: choice.accountId == null
                        ? ''
                        : personPhotoPath(circleId, choice.accountId),
                    avatarCode: choice.avatarCode,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(choice.name),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
