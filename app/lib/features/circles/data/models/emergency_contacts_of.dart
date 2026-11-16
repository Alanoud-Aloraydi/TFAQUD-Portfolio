import 'package:app/features/circles/data/models/emergency_contact_model.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';

/// The emergency contacts of an answer, in the order the server sent them;
/// none when the answer carries none.
List<EmergencyContact> emergencyContactsOf(Object? value) {
  return <EmergencyContact>[
    for (final Object? item in (value as List<dynamic>? ?? <dynamic>[]))
      EmergencyContactModel.fromJson(item as Map<String, dynamic>).toEntity(),
  ];
}
