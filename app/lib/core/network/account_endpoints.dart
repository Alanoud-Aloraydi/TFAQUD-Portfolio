/// The signed-in account's routes of the API (backend/app/users/routes.py):
/// the account, its profile, its photo and its push subscription.
abstract final class AccountEndpoints {
  /// PUT: the signed-in account's names, and the birth date and city when
  /// sent (`ProfileRemoteDataSource`; `save_profile` on the server).
  static const String profile = '/accounts/me/profile';
  static const String account = '/accounts/me';

  static const String accountPhoto = '/accounts/me/photo';
  static const String accountAvatar = '/accounts/me/avatar';
  static const String pushSubscription = '/accounts/me/push-subscription';
}
