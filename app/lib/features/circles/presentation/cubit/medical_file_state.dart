import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_choice.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:equatable/equatable.dart';

enum MedicalFileStatus { loading, ready, failure }

/// What the medical file page shows: the file read from the server, and the
/// contact form when one is open.
class MedicalFileState extends Equatable {
  const MedicalFileState({
    this.status = MedicalFileStatus.loading,
    this.file,
    this.messageKey,
    this.form,
    this.sessionEnded = false,
    this.choices,
  });

  final MedicalFileStatus status;
  final MedicalFile? file;

  /// Why the first load failed: a key in assets/translations.
  final String? messageKey;

  /// The open contact form, or null.
  final ContactForm? form;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  /// The circle members a new contact can be picked from; null until read.
  final List<ContactChoice>? choices;

  MedicalFileState copyWith({
    MedicalFileStatus? status,
    MedicalFile? file,
    String? messageKey,
    ContactForm? form,
    bool clearForm = false,
    bool? sessionEnded,
    List<ContactChoice>? choices,
  }) {
    return MedicalFileState(
      status: status ?? this.status,
      file: file ?? this.file,
      messageKey: messageKey ?? this.messageKey,
      form: clearForm ? null : (form ?? this.form),
      sessionEnded: sessionEnded ?? this.sessionEnded,
      choices: choices ?? this.choices,
    );
  }

  @override
  List<Object?> get props => [
    status,
    file,
    messageKey,
    form,
    sessionEnded,
    choices,
  ];
}
