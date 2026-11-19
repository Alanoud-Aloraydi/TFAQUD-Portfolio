import 'package:app/core/network/dio_client.dart';
import 'package:app/features/medications/data/datasources/base_medications_remote_data_source.dart';
import 'package:app/features/medications/data/datasources/medication_dose_requests.dart';
import 'package:app/features/medications/data/datasources/medication_extra_dose_requests.dart';
import 'package:app/features/medications/data/datasources/medication_plan_requests.dart';
import 'package:injectable/injectable.dart';

export 'package:app/features/medications/data/datasources/base_medications_remote_data_source.dart';

/// Sends medications requests to the API.
@LazySingleton(as: BaseMedicationsRemoteDataSource)
class MedicationsRemoteDataSource
    with
        MedicationPlanRequests,
        MedicationDoseRequests,
        MedicationExtraDoseRequests
    implements BaseMedicationsRemoteDataSource {
  MedicationsRemoteDataSource(this.client);

  @override
  final DioClient client;
}
