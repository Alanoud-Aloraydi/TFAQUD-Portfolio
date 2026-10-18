import 'package:injectable/injectable.dart';

@Singleton(order: 1)
class LocalKeysService {
  LocalKeysService();

  // Auth Keys
  final String accessToken = 'access_token';
  final String refreshToken = 'refresh_token';
}
