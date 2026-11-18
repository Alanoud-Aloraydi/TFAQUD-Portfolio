/// The router patterns of a circle's medical file and emergency card, in
/// the detailed and the simplified mode. The circle id is part of the
/// address, so the pages work after a reload in the browser.
abstract final class MedicalFilePaths {
  static const String medicalFilePath = '/circle/:circleId/medical-file';
  static const String medicalFileEditPath =
      '/circle/:circleId/medical-file/edit';
  static const String emergencyCardPath = '/circle/:circleId/emergency-card';
  static const String simplifiedMedicalFilePath =
      '/simplifiedMode/:circleId/medical-file';
  static const String simplifiedMedicalFileEditPath =
      '/simplifiedMode/:circleId/medical-file/edit';
  static const String simplifiedEmergencyCardPath =
      '/simplifiedMode/:circleId/emergency-card';
}
