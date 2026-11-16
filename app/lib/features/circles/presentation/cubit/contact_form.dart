import 'package:app/core/utils/saudi_mobile.dart';
import 'package:equatable/equatable.dart';

/// The form of one emergency contact, open below the list while the user adds
/// a contact or changes one.
class ContactForm extends Equatable {
  const ContactForm({
    this.contactId,
    this.relation,
    this.name = '',
    this.phone = '',
    this.showErrors = false,
    this.saving = false,
    this.errorKey,
  });

  /// The contact that is changed, or null for a new contact.
  final String? contactId;

  /// One of [MedicalOptions.contactRelations], or null until the user picks.
  final String? relation;
  final String name;

  /// The nine digits of the number, written 0-9, without the country code.
  final String phone;

  /// True after a tap on "حفظ" with a missing answer.
  final bool showErrors;
  final bool saving;

  /// Why the last save failed: a key in assets/translations.
  final String? errorKey;

  bool get isNew => contactId == null;

  /// [phone] is a whole Saudi mobile number ([SaudiMobile]); emergency
  /// contacts are Saudi numbers (see `saudi_mobile.dart`).
  bool get phoneValid => SaudiMobile.isValid(phone);

  ContactForm copyWith({
    String? relation,
    String? name,
    String? phone,
    bool? showErrors,
    bool? saving,
    String? errorKey,
    bool clearError = false,
  }) {
    return ContactForm(
      contactId: contactId,
      relation: relation ?? this.relation,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      showErrors: showErrors ?? this.showErrors,
      saving: saving ?? this.saving,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }

  @override
  List<Object?> get props => [
    contactId,
    relation,
    name,
    phone,
    showErrors,
    saving,
    errorKey,
  ];
}
