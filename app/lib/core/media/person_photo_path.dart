import 'package:app/core/network/circle_endpoints.dart';

String personPhotoPath(String circleId, String? accountId) => accountId == null
    ? CircleEndpoints.patientPhoto(circleId)
    : CircleEndpoints.memberPhoto(circleId, accountId);
