part of '../circles_remote_data_source.dart';

/// The calls for the account and a circle overview.
mixin _AccountRequests implements CircleAccountApi {
  DioClient get _client;

  @override
  Future<AccountModel> getAccount() async {
    final response = await _client.get(ApiEndpoints.account);
    return AccountModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleOverviewModel> getCircleOverview(String circleId) async {
    final response = await _client.get(ApiEndpoints.circle(circleId));
    return CircleOverviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAccount(AccountDeletion deletion) async {
    final PatientChoice? choice = deletion.patientChoice;
    final Map<String, dynamic> body = <String, dynamic>{
      if (choice != null)
        'patient_choice': choice == PatientChoice.delete
            ? 'delete'
            : 'continue',
      if (deletion.deleteLastManagedCircles)
        'delete_last_managed_circles': true,
    };
    // An account with no circles sends no body.
    await _client.delete(
      ApiEndpoints.account,
      data: body.isEmpty ? null : body,
    );
  }
}
