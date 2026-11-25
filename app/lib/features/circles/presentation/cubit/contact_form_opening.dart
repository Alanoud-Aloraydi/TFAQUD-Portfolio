import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opening the contact form, on a new contact or one already saved, and
/// closing it again.
mixin ContactFormOpening on Cubit<MedicalFileState>, MedicalFileScope {
  /// Opens an empty form, when there is room for one more contact, and
  /// reads the circle's members it can be picked from.
  void startAdd() {
    final MedicalFile? file = state.file;
    if (file == null || !file.canAddContact || state.form != null) return;
    emit(state.copyWith(form: const ContactForm()));
    loadChoices();
  }

  /// The members with a Saudi number, read once. The form works without
  /// them: a failure only leaves the list out.
  Future<void> loadChoices() async {
    if (state.choices != null) return;
    final result = await circles.getCircleOverview(circleId);
    if (isClosed) return;
    final CircleOverview? overview = result.tryGetSuccess();
    if (overview == null) return;
    emit(state.copyWith(choices: contactChoicesOf(overview)));
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
              relationOther: contact.relationOther ?? '',
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
}

/// The members a contact can be picked from: those with a Saudi number,
/// the patient left out, since the patient is who the contacts are for.
List<ContactChoice> contactChoicesOf(CircleOverview overview) =>
    <ContactChoice>[
      for (final CircleMember member in overview.members)
        if (!member.isPatient &&
            member.phoneNumber != null &&
            SaudiMobile.isValid(SaudiMobile.national(member.phoneNumber!)))
          ContactChoice(
            name: member.name,
            phone: SaudiMobile.national(member.phoneNumber!),
            accountId: member.accountId,
            avatarCode: member.avatarCode,
          ),
    ];

/// What [ContactForm] needs before it can be saved.
extension ContactFormChecks on ContactForm {
  /// A relation is picked, and «أخرى» has its words.
  bool get relationAnswered =>
      relation != null &&
      (relation != MedicalOptions.other || relationOther.trim().isNotEmpty);

  /// The words of «أخرى» are missing after a tap on «حفظ».
  bool get relationOtherMissing =>
      showErrors && relation == MedicalOptions.other && !relationAnswered;

  /// A whole Saudi mobile number: emergency contacts are Saudi numbers.
  bool get phoneValid => SaudiMobile.isValid(phone);
}
