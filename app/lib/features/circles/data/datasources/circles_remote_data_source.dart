import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/circles/data/models/circle_model.dart';
import 'package:app/features/circles/data/models/circle_overview_model.dart';
import 'package:app/features/circles/data/models/circle_request_model.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/data/models/medical_file_model.dart';
import 'package:app/features/circles/data/models/new_patient_circle_model.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';

part 'package:app/features/circles/data/datasources/circles_remote_data_source/account_api.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/account_requests.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/circle_request_api.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/circle_request_requests.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/medical_api.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/medical_requests.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/member_api.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/member_requests.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/reply_api.dart';
part 'package:app/features/circles/data/datasources/circles_remote_data_source/reply_requests.dart';

/// Sends base circles requests to the API.
abstract class BaseCirclesRemoteDataSource
    implements
        CircleAccountApi,
        CircleMemberApi,
        CircleRequestApi,
        CircleReplyApi,
        CircleMedicalApi {}

/// Sends circles requests to the API.
class CirclesRemoteDataSource
    with
        _AccountRequests,
        _MemberRequests,
        _CircleRequestRequests,
        _ReplyRequests,
        _MedicalRequests
    implements BaseCirclesRemoteDataSource {
  CirclesRemoteDataSource(this._client);

  @override
  final DioClient _client;
}
