import 'package:injectable/injectable.dart';

@Singleton(order: 1)
class LocalKeysService {
  LocalKeysService();

  final String sessionTokens = 'session_tokens';

  // Legacy keys remain readable until the next session write.
  final String accessToken = 'access_token';
  final String refreshToken = 'refresh_token';
}
