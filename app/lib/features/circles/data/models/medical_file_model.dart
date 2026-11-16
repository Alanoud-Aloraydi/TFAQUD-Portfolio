export 'package:app/features/circles/data/models/emergency_card_model.dart';
export 'package:app/features/circles/data/models/emergency_contact_model.dart';
export 'package:app/features/circles/data/models/medical_profile_answer_model.dart';
export 'package:app/features/circles/data/models/medical_profile_json.dart';
export 'package:app/features/circles/data/models/patient_update_model.dart';
import 'package:app/core/utils/time_zones.dart';
import 'package:app/features/circles/data/models/medical_profile_json.dart';
import 'package:app/features/circles/data/models/emergency_contacts_of.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';

/// The answer of GET /api/v1/circles/{id}/medical-profile.
class MedicalFileModel {
  const MedicalFileModel(this._entity);

  final MedicalFile _entity;

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> patient =
        json['patient'] as Map<String, dynamic>;
    return MedicalFileModel(
      MedicalFile(
        patient: PatientBasics(
          firstName: patient['first_name'] as String? ?? '',
          lastName: patient['last_name'] as String? ?? '',
          birthDate: parseDate(patient['birth_date'] as String),
          city: patient['city'] as String? ?? '',
          hasAccount: patient['has_account'] as bool? ?? false,
          latitude: (patient['latitude'] as num?)?.toDouble(),
          longitude: (patient['longitude'] as num?)?.toDouble(),
          timeZone: patient['time_zone'] as String? ?? defaultPatientZone,
        ),
        profile: MedicalProfileJson.fromJson(
          json['medical_profile'] as Map<String, dynamic>,
        ),
        contacts: emergencyContactsOf(json['emergency_contacts']),
      ),
    );
  }

  MedicalFile toEntity() => _entity;

  /// `YYYY-MM-DD` to a date without a time zone. The date is built from its
  /// parts, so no time zone can move it to another day.
  static DateTime parseDate(String iso) {
    final List<String> parts = iso.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
