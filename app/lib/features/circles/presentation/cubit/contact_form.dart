import 'package:equatable/equatable.dart';

/// The open form of one emergency contact; its checks: [ContactFormChecks].
class ContactForm extends Equatable {
  const ContactForm({
    this.contactId,
    this.relation,
    this.relationOther = '',
    this.name = '',
    this.phone = '',
    this.showErrors = false,
    this.saving = false,
    this.errorKey,
  });

  /// The contact that is changed, or null for a new contact.
  final String? contactId;

  /// One of [MedicalOptions.contactRelations], or null until the user picks,
  /// and the words typed for «أخرى», kept if they pick another and back.
  final String? relation;
  final String relationOther;
  final String name;

  /// The nine digits of the number, written 0-9, without the country code.
  final String phone;

  /// True after a tap on "حفظ" with a missing answer.
  final bool showErrors;
  final bool saving;

  /// Why the last save failed: a key in assets/translations.
  final String? errorKey;

  bool get isNew => contactId == null;

  ContactForm copyWith({
    String? relation,
    String? relationOther,
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
      relationOther: relationOther ?? this.relationOther,
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
    relationOther,
    name,
    phone,
    showErrors,
    saving,
    errorKey,
  ];
}
