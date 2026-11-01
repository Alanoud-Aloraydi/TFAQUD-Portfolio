import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The card that adds an emergency contact or changes one (CIRCLE-05): the
/// relation chips, the name, the number, and the save and cancel buttons. A
/// contact that already exists also has a delete button.
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
    _phone = TextEditingController(
      text: PhoneNumberFormatter.display(widget.form.phone),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ContactForm form = widget.form;
    final TextTheme text = Theme.of(context).textTheme;
    final String requiredText = context.tr('circles.field_required');
    final bool phoneInvalid =
        form.showErrors && !MedicalFileCubit.isValidPhone(form.phone);
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
              color: AppSemanticColors.textSupporting,
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
                  child: Text(context.tr('circles.contact_cancel')),
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
                icon: const Icon(
                  CupertinoIcons.delete,
                  size: AppSizes.iconSmall,
                ),
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
