part of '../circles_remote_data_source.dart';

/// The signed-in account and the overview of one circle.
abstract interface class CircleAccountApi {
  /// GET /api/v1/accounts/me.
  Future<AccountModel> getAccount();

  /// GET /api/v1/circles/{id}.
  Future<CircleOverviewModel> getCircleOverview(String circleId);

  /// DELETE /api/v1/accounts/me.
  Future<void> deleteAccount(AccountDeletion deletion);
}
