import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';

/// The contact as the server takes it: the number typed in its national
/// form goes out in its international one.
ContactDraft contactDraftOf(ContactForm form, String name, String relation) =>
    ContactDraft(
      name: name,
      relation: relation,
      phoneNumber: SaudiMobile.international(form.phone),
    );
