import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the emergency-contact card needs from the page that opens it: the
/// answers so far, and what to do with each change the person makes.
class ContactFormProps {
  const ContactFormProps({
    required this.form,
    required this.onRelation,
    required this.onRelationOther,
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

  /// Receives the words typed for «أخرى».
  final ValueChanged<String> onRelationOther;
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
}

/// The typed name, number and words of «أخرى» of the contact card. They
/// start from the form, so the page gives the card a key of its own for each
/// contact.
class ContactFormText {
  ContactFormText(ContactForm form)
    : name = TextEditingController(text: form.name),
      phone = TextEditingController(text: SaudiMobile.group(form.phone)),
      relationOther = TextEditingController(text: form.relationOther);

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController relationOther;

  /// Puts a member's name and number in the fields.
  void fillFrom(ContactChoice choice) {
    name.text = choice.name;
    phone.text = SaudiMobile.group(choice.phone);
  }

  void dispose() {
    name.dispose();
    phone.dispose();
    relationOther.dispose();
  }
}

/// «متحقق» when the contact's number uses تفقُد, «غير متحقق» when not.
/// Words and an icon, never colour alone.
class ContactVerifiedBadge extends StatelessWidget {
  const ContactVerifiedBadge({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) => StatusBadge(
    text: context.tr(
      verified ? 'circles.contact_verified' : 'circles.contact_unverified',
    ),
    tone: verified ? StatusTone.success : StatusTone.muted,
    icon: verified ? ActionIcons.checkCircle : NoticeIcons.warningCircle,
  );
}
