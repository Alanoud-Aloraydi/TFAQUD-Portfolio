import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';

/// The contact as the server takes it, from a form whose relation is
/// answered: the number typed in its national form goes out in its
/// international one, and the words of «أخرى» only with «أخرى».
ContactDraft contactDraftOf(ContactForm form, String name) => ContactDraft(
  name: name,
  relation: form.relation!,
  relationOther: form.relation == MedicalOptions.other
      ? form.relationOther.trim()
      : null,
  phoneNumber: SaudiMobile.international(form.phone),
);
