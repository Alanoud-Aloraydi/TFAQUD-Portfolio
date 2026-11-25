import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/datasources/device_zone.dart';
import 'package:app/features/circles/data/models/circle_request_model.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/data/models/new_patient_circle_model.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/repositories/circles_repository.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

part 'package:app/features/circles/data/repositories/circles_repository/account_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/circle_creation_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/circle_failure_mapping.dart';
part 'package:app/features/circles/data/repositories/circles_repository/contact_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/inbox_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/manager_invitation_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/medical_file_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/member_calls.dart';
part 'package:app/features/circles/data/repositories/circles_repository/reply_calls.dart';

/// The server owns the circles, their members and their medical files.
class CirclesRepositoryImpl
    with
        _AccountCalls,
        _ManagerInvitationCalls,
        _MemberCalls,
        _CircleCreationCalls,
        _InboxCalls,
        _ReplyCalls,
        _MedicalFileCalls,
        _ContactCalls
    implements CirclesRepository {
  CirclesRepositoryImpl(this._remote, this._deviceZone);

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
