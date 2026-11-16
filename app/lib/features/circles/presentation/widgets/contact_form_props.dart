import 'package:app/features/circles/presentation/cubit/contact_choice.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:flutter/material.dart';

/// What the emergency-contact card needs from the page that opens it: the
/// answers so far, and what to do with each change the person makes.
class ContactFormProps {
  const ContactFormProps({
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
}
