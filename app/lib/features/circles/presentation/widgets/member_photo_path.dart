import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';

/// Where a member's portrait is read from. A patient with their own account
/// is one person with one photo, read through the account endpoint so the
/// circle tab and the profile stay in sync.
String memberPhotoPath(
  CircleMember member, {
  required String circleId,
  required bool patientIsYou,
}) {
  if (!member.isPatient) return personPhotoPath(circleId, member.accountId);
  return patientIsYou
      ? ApiEndpoints.accountPhoto
      : ApiEndpoints.patientPhoto(circleId);
}
