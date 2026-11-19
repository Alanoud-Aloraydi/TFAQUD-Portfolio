import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/circles/presentation/cubit/contact_choice.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_buttons.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_text.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_title.dart';
import 'package:app/features/circles/presentation/widgets/contact_member_choices.dart';
import 'package:app/features/circles/presentation/widgets/contact_name_phone_fields.dart';
import 'package:app/features/circles/presentation/widgets/contact_relation_chips.dart';
import 'package:flutter/material.dart';

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
