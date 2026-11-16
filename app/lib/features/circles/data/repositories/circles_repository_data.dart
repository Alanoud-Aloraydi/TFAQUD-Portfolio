import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/datasources/device_zone.dart';
import 'package:app/features/circles/data/models/circle_request_model.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/data/models/new_patient_circle_model.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

part 'circles_repository/account_calls.dart';
part 'circles_repository/circle_creation_calls.dart';
part 'circles_repository/circle_failure_mapping.dart';
part 'circles_repository/contact_calls.dart';
part 'circles_repository/inbox_calls.dart';
part 'circles_repository/manager_invitation_calls.dart';
part 'circles_repository/medical_file_calls.dart';
part 'circles_repository/member_calls.dart';
part 'circles_repository/reply_calls.dart';

/// The server owns the circles, their members and their medical files.
@LazySingleton(as: CirclesRepositoryDomain)
class CirclesRepositoryData
    with
        _AccountCalls,
        _ManagerInvitationCalls,
        _MemberCalls,
        _CircleCreationCalls,
        _InboxCalls,
        _ReplyCalls,
        _MedicalFileCalls,
        _ContactCalls
    implements CirclesRepositoryDomain {
  CirclesRepositoryData(this._remote, this._deviceZone);

  @override
  final BaseCirclesRemoteDataSource _remote;
  final DeviceZone _deviceZone;

  /// A new patient's zone: Saudi Arabia's for a city of the list; for a
  /// city typed by hand, this phone's zone. For a self circle or a completed
  /// request the patient is the person on this phone; for a patient without
  /// the app it is the best first guess of the person who cares for them.
  /// Either can be changed later on the medical file.
  @override
  Future<String> _newPatientZone(String city) async =>
      SaudiCities.zoneOf(city) ?? await _deviceZone.current();
}
