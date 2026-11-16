import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter/material.dart';

/// The typed name and number of the contact card. They start from the form,
/// so the page gives the card a key of its own for each contact.
class ContactFormText {
  ContactFormText(ContactForm form)
    : name = TextEditingController(text: form.name),
      phone = TextEditingController(text: SaudiMobile.group(form.phone));

  final TextEditingController name;
  final TextEditingController phone;

  /// Puts a member's name and number in the fields.
  void fillFrom(ContactChoice choice) {
    name.text = choice.name;
    phone.text = SaudiMobile.group(choice.phone);
  }

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}
