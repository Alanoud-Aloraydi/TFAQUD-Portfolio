import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:equatable/equatable.dart';

enum MedicalFileStatus { loading, ready, failure }

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

/// What the medical file page shows: the file read from the server, and the
/// contact form when one is open.
class MedicalFileState extends Equatable {
  const MedicalFileState({
    this.status = MedicalFileStatus.loading,
    this.file,
    this.messageKey,
    this.form,
    this.sessionEnded = false,
  });

  final MedicalFileStatus status;
  final MedicalFile? file;

  /// Why the first load failed: a key in assets/translations.
  final String? messageKey;

  /// The open contact form, or null.
  final ContactForm? form;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  MedicalFileState copyWith({
    MedicalFileStatus? status,
    MedicalFile? file,
    ContactForm? form,
    bool clearForm = false,
    bool? sessionEnded,
  }) {
    return MedicalFileState(
      status: status ?? this.status,
      file: file ?? this.file,
      messageKey: messageKey,
      form: clearForm ? null : (form ?? this.form),
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }

  @override
  List<Object?> get props => [status, file, messageKey, form, sessionEnded];
}
