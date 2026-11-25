import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_buttons.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/contact_relation_chips.dart';
import 'package:easy_localization/easy_localization.dart';
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
