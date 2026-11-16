import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Putting a saved contact in the file on screen, and telling the other
/// pages that the file changed.
mixin ContactKept on Cubit<MedicalFileState>, MedicalFileScope {
  void keepContact(
    EmergencyContact saved, {
    required bool isNew,
    required MedicalFile file,
  }) {
    final MedicalFile current = state.file ?? file;
    final MedicalFile updated = current.copyWith(
      contacts: isNew
          ? <EmergencyContact>[...current.contacts, saved]
          : <EmergencyContact>[
              for (final EmergencyContact contact in current.contacts)
                contact.id == saved.id ? saved : contact,
            ],
    );
    emit(state.copyWith(file: updated, clearForm: true));
    circles.medicalFileSaved(circleId, updated);
  }
}
