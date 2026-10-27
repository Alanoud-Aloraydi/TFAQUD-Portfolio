import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The medical file page (CIRCLE-05): reads the file of one circle and adds,
/// changes and removes its emergency contacts. The health answers, the birth
/// date and the city are changed on the edit page.
class MedicalFileCubit extends Cubit<MedicalFileState> {
  MedicalFileCubit(this._circles, this.circleId)
    : super(const MedicalFileState());

  final CirclesUseCase _circles;
  final String circleId;

  /// A Saudi mobile number without the country code or a leading zero: nine
  /// digits that start with 5. The same rule as the sign-in page.
  static final RegExp _phonePattern = RegExp(r'^5[0-9]{8}$');

  static const String countryCode = '+966';

  int _revision = 0;

  /// Reads the file. The first read shows the loading state; a later read (when
  /// the person comes back from the edit page) keeps the page on screen until
  /// the new file arrives, and a failure of a later read keeps the old file.
  Future<void> load() async {
    final int revision = ++_revision;
    if (state.status != MedicalFileStatus.ready) {
      emit(const MedicalFileState());
    }
    final result = await _circles.getMedicalFile(circleId);
    if (isClosed || revision != _revision) return;
    result.when(
      (MedicalFile file) =>
          emit(state.copyWith(status: MedicalFileStatus.ready, file: file)),
      (Failure failure) {
        if (state.status == MedicalFileStatus.ready) {
          if (_ended(failure)) emit(state.copyWith(sessionEnded: true));
          return;
        }
        emit(
          MedicalFileState(
            status: MedicalFileStatus.failure,
            messageKey: failure.messageKey,
            sessionEnded: _ended(failure),
          ),
        );
      },
    );
  }

  // ---- the contact form ------------------------------------------------

  /// Opens an empty form, when there is room for one more contact.
  void startAdd() {
    final MedicalFile? file = state.file;
    if (file == null || !file.canAddContact || state.form != null) return;
    emit(state.copyWith(form: const ContactForm()));
  }

  /// Opens the form with the saved values of a contact.
  void startEdit(String contactId) {
    final MedicalFile? file = state.file;
    if (file == null || state.form != null) return;
    for (final EmergencyContact contact in file.contacts) {
      if (contact.id == contactId) {
        emit(
          state.copyWith(
            form: ContactForm(
              contactId: contact.id,
              relation: contact.relation,
              name: contact.name,
              phone: contact.nationalNumber,
            ),
          ),
        );
        return;
      }
    }
  }

  void cancelForm() {
    if (state.form?.saving ?? false) return;
    emit(state.copyWith(clearForm: true));
  }

  void relationChosen(String code) => _edit(
    (ContactForm form) => form.copyWith(relation: code, clearError: true),
  );

  void nameChanged(String value) =>
      _edit((ContactForm form) => form.copyWith(name: value, clearError: true));

  /// [digits] are the digits the user typed, already written 0-9.
  void phoneChanged(String digits) => _edit(
    (ContactForm form) => form.copyWith(phone: digits, clearError: true),
  );

  /// True for nine digits that start with 5. [digits] are written 0-9.
  static bool isValidPhone(String digits) => _phonePattern.hasMatch(digits);

  bool get isPhoneValid => isValidPhone(state.form?.phone ?? '');

  void _edit(ContactForm Function(ContactForm form) change) {
    final ContactForm? form = state.form;
    if (form == null || form.saving) return;
    emit(state.copyWith(form: change(form)));
  }

  /// Saves the open form: a new contact is added, an old one is changed.
  /// Returns true when the server saved it.
  Future<bool> saveContact() async {
    final ContactForm? form = state.form;
    final MedicalFile? file = state.file;
    if (form == null || file == null || form.saving) return false;
    final String name = form.name.trim();
    final String? relation = form.relation;
    if (relation == null || name.isEmpty || !isPhoneValid) {
      emit(state.copyWith(form: form.copyWith(showErrors: true)));
      return false;
    }
    emit(
      state.copyWith(
        form: form.copyWith(saving: true, showErrors: false, clearError: true),
      ),
    );
    final ContactDraft draft = ContactDraft(
      name: name,
      relation: relation,
      phoneNumber: '$countryCode${form.phone}',
    );
    final result = form.isNew
        ? await _circles.addContact(circleId, draft)
        : await _circles.updateContact(circleId, form.contactId!, draft);
    if (isClosed) return false;
    return result.when(
      (EmergencyContact saved) {
        final MedicalFile current = state.file ?? file;
        emit(
          state.copyWith(
            file: current.copyWith(
              contacts: form.isNew
                  ? <EmergencyContact>[...current.contacts, saved]
                  : <EmergencyContact>[
                      for (final EmergencyContact contact in current.contacts)
                        contact.id == saved.id ? saved : contact,
                    ],
            ),
            clearForm: true,
          ),
        );
        return true;
      },
      (Failure failure) {
        emit(
          state.copyWith(
            form: (state.form ?? form).copyWith(
              saving: false,
              errorKey: failure.messageKey,
            ),
            sessionEnded: _ended(failure),
          ),
        );
        // The list on screen is out of date: the contact is gone, or another
        // manager added the fifth one.
        if (failure is NotFoundFailure || failure is TooManyContactsFailure) {
          unawaited(load());
        }
        return false;
      },
    );
  }

  /// Removes the contact of the open form. Returns true when it is gone.
  Future<bool> deleteContact() async {
    final ContactForm? form = state.form;
    final MedicalFile? file = state.file;
    final String? contactId = form?.contactId;
    if (form == null || file == null || contactId == null || form.saving) {
      return false;
    }
    emit(
      state.copyWith(form: form.copyWith(saving: true, clearError: true)),
    );
    final result = await _circles.deleteContact(circleId, contactId);
    if (isClosed) return false;
    return result.when(
      (_) {
        emit(state.copyWith(file: _without(contactId), clearForm: true));
        return true;
      },
      (Failure failure) {
        if (failure is NotFoundFailure) {
          // Another manager removed it first: it is gone either way.
          emit(state.copyWith(file: _without(contactId), clearForm: true));
          return true;
        }
        emit(
          state.copyWith(
            form: (state.form ?? form).copyWith(
              saving: false,
              errorKey: failure.messageKey,
            ),
            sessionEnded: _ended(failure),
          ),
        );
        return false;
      },
    );
  }

  MedicalFile _without(String contactId) {
    final MedicalFile current = state.file!;
    return current.copyWith(
      contacts: <EmergencyContact>[
        for (final EmergencyContact contact in current.contacts)
          if (contact.id != contactId) contact,
      ],
    );
  }

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
